using AbayundaTok.BLL.Interfaces;
using Microsoft.AspNetCore.Http;
using Minio.DataModel.Args;
using Minio;
using Diplom.DAL.Entities;
using System.Diagnostics;
using System.Text;

namespace AbayundaTok.BLL.Services
{
    public class VideoService : IVideoService
    {
        private readonly IMinioClient _minioClient;
        private const string BucketName = "videos";
        private const string FfmpegPath = @"C:\Program Files\ffmpeg-7.1.1-full_build\bin\ffmpeg.exe";

        public VideoService(IMinioClient minioClient)
        {
            _minioClient = minioClient;
        }

        // Создаем бакет при первом запуске (если его нет)
        private async Task EnsureBucketExistsAsync()
        {
            var exists = await _minioClient.BucketExistsAsync(
                new BucketExistsArgs().WithBucket(BucketName)
            );

            if (!exists)
                await _minioClient.MakeBucketAsync(
                    new MakeBucketArgs().WithBucket(BucketName)
                );
        }

        // Загрузка видео и конвертация в HLS
        public async Task<string> UploadVideoAsync(IFormFile file, string videoName)
        {
            await EnsureBucketExistsAsync();

            var videoId = Guid.NewGuid().ToString();
            var tempPath = Path.GetTempPath();
            var originalPath = Path.Combine(tempPath, $"{videoId}_original.mp4");
            var hlsPath = Path.Combine(tempPath, videoId);

            try
            {
                // 1. Создаем папку для HLS-чанков
                Directory.CreateDirectory(hlsPath);

                // 2. Сохраняем исходный файл
                await using (var stream = new FileStream(originalPath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                // 3. Конвертируем в HLS
                var ffmpegCmd = $"-i \"{originalPath}\" -c:v libx264 -hls_time 10 -hls_list_size 0 \"{Path.Combine(hlsPath, "master.m3u8")}\"";
                await ExecuteFFmpegCommand(ffmpegCmd);

                // 4. Загружаем чанки в MinIO
                var chunks = Directory.GetFiles(hlsPath);
                if (chunks.Length == 0)
                {
                    throw new Exception("No HLS chunks were generated");
                }

                foreach (var chunk in chunks)
                {
                    var objectName = $"{videoId}/{Path.GetFileName(chunk)}";
                    await _minioClient.PutObjectAsync(
                        new PutObjectArgs()
                            .WithBucket(BucketName)
                            .WithObject(objectName)
                            .WithFileName(chunk)
                    );
                }

                return videoId;
            }
            finally
            {
                // 5. Очистка временных файлов
                if (File.Exists(originalPath))
                {
                    File.Delete(originalPath);
                }

                if (Directory.Exists(hlsPath))
                {
                    Directory.Delete(hlsPath, true);
                }
            }
        }

        // Получение видео как потока (прямая загрузка)
        public async Task<Stream> GetVideoStreamAsync(int videoId)
        {
            var stream = new MemoryStream();
            await _minioClient.GetObjectAsync(
                new GetObjectArgs()
                    .WithBucket(BucketName)
                    .WithObject($"{videoId}/master.m3u8")
                    .WithCallbackStream(st => st.CopyTo(stream))
            );
            stream.Position = 0;
            return stream;
        }

        // Получение HLS-плейлиста
        public async Task<string> GetVideoPlaylistAsync(int videoId)
        {
            var playlistUrl = await _minioClient.PresignedGetObjectAsync(
                new PresignedGetObjectArgs()
                    .WithBucket(BucketName)
                    .WithObject($"{videoId}/master.m3u8")
                    .WithExpiry(3600) // Ссылка действует 1 час
            );
            return playlistUrl;
        }

        // Метаданные видео (можно расширить)
        public async Task<Video> GetVideoMetadataAsync(int videoId)
        {
            var meta = new Video
            {
                Id = videoId,
                CreatedAt = DateTime.UtcNow
            };
            return meta;
        }

        // Вспомогательный метод для запуска FFmpeg
        private async Task ExecuteFFmpegCommand(string command)
        {
            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = FfmpegPath,
                    Arguments = command,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                },
                EnableRaisingEvents = true
            };

            var output = new StringBuilder();
            var error = new StringBuilder();

            // Асинхронное чтение выходных потоков
            process.OutputDataReceived += (sender, e) => output.AppendLine(e.Data);
            process.ErrorDataReceived += (sender, e) => error.AppendLine(e.Data);

            try
            {
                process.Start();

                // Начинаем асинхронное чтение потоков
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();

                // Ожидание завершения с таймаутом (30 секунд)
                var timeout = TimeSpan.FromSeconds(30);
                if (!await WaitForExitAsync(process, timeout))
                {
                    process.Kill();
                    throw new TimeoutException($"FFmpeg execution timed out after {timeout.TotalSeconds} seconds");
                }

                if (process.ExitCode != 0)
                {
                    throw new Exception($"FFmpeg failed with code {process.ExitCode}. Error: {error}");
                }
            }
            finally
            {
                process.Dispose();
            }
        }
        private Task<bool> WaitForExitAsync(Process process, TimeSpan timeout)
        {
            var tcs = new TaskCompletionSource<bool>();

            process.Exited += (sender, args) => tcs.TrySetResult(true);

            if (process.HasExited)
                return Task.FromResult(true);

            var timeoutTask = Task.Delay(timeout)
                .ContinueWith(_ => tcs.TrySetResult(false));

            return Task.WhenAny(tcs.Task, timeoutTask)
                .ContinueWith(_ => tcs.Task.Result);
        }
    }
}

