using AbayundaTok.BLL.Interfaces;
using Microsoft.AspNetCore.Http;
using Minio.DataModel.Args;
using Minio;
using Diplom.DAL.Entities;
using System.Diagnostics;
using System.Text;
using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using AbayundaTok.DAL;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using Microsoft.EntityFrameworkCore;
using AbayundaTok.BLL.DTO;
using System.Text.Json;
using AbayundaTok.DAL.Constants;

namespace AbayundaTok.BLL.Services
{
    public class VideoService : IVideoService
    {
        private readonly IMinioClient _minioClient;
        private const string BucketName = "videos";
        private const string FfmpegPath = @"C:\Program Files\ffmpeg-7.1.1-full_build\bin\ffmpeg.exe";
        private readonly AppDbContext _dbContext;
        public VideoService(IMinioClient minioClient, AppDbContext dbContext)
        {
            _minioClient = minioClient;
            _dbContext = dbContext;
        }

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

        public async Task<Video> UploadVideoAsync(IFormFile file,string description, string userId)
        {
            await EnsureBucketExistsAsync();
            await EnsureThumbnailBucketExistsAsync();

            var videoUrl = Guid.NewGuid().ToString();
            var tempPath = Path.GetTempPath();
            var originalPath = Path.Combine(tempPath, $"{videoUrl}_original.mp4");
            var hlsPath = Path.Combine(tempPath, videoUrl);
            var thumbnailPath = Path.Combine(tempPath, $"{videoUrl}_thumbnail.jpg");

            try
            {
                Directory.CreateDirectory(hlsPath);
                await using (var stream = new FileStream(originalPath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }
                var ffmpegThumbnailCmd = $"-i \"{originalPath}\" -ss 00:00:00.000 -vframes 1 \"{thumbnailPath}\"";
                await ExecuteFFmpegCommand(ffmpegThumbnailCmd);

                if (File.Exists(thumbnailPath))
                {
                    var thumbnailObjectName = $"{videoUrl}.jpg";
                    await _minioClient.PutObjectAsync(
                        new PutObjectArgs()
                            .WithBucket("thumbnails")
                            .WithObject(thumbnailObjectName)
                            .WithContentType("image/jpeg")
                            .WithFileName(thumbnailPath)
                    );
                    Console.WriteLine($"✅ Превью загружено: {thumbnailObjectName}");
                }
                var ffmpegCmd = $"-i \"{originalPath}\" " +
                "-c:v h264 " +
                "-preset fast " +
                "-b:v 800k " +
                "-vf \"scale=-2:720\" " +
                "-c:a aac " +
                "-b:a 128k " +
                "-hls_time 1 " +
                "-hls_playlist_type vod " +
                $"-hls_segment_filename \"{Path.Combine(hlsPath, "%03d.ts")}\" " +
                $"-hls_base_url \"{URL.Url}/videos/{videoUrl}/\" " +
                $"\"{Path.Combine(hlsPath, "master.m3u8")}\"";

                await ExecuteFFmpegCommand(ffmpegCmd);

                var chunks = Directory.GetFiles(hlsPath);
                if (chunks.Length == 0)
                {
                    throw new Exception("No HLS chunks were generated");
                }

                foreach (var chunk in chunks)
                {
                    var objectName = $"{videoUrl}/{Path.GetFileName(chunk)}";

                    try
                    {
                        await _minioClient.PutObjectAsync(
                            new PutObjectArgs()
                                .WithBucket(BucketName)
                                .WithObject(objectName)
                                .WithContentType("application/vnd.apple.mpegurl")
                                .WithFileName(chunk)
                        );

                        Console.WriteLine($"✅ Загружено: {objectName}");
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"❌ Ошибка при загрузке {objectName}: {ex.Message}");
                    }
                }

                var video = new Video
                {
                    UserId = userId,
                    VideoUrl = videoUrl,
                    Description = description,
                    ThumbnailUrl = $"{URL.Url}/thumbnails/{videoUrl}.jpg"
                };

                try
                {
                    _dbContext.Videos.Add(video);
                    await _dbContext.SaveChangesAsync();
                }
                catch (Exception e)
                {
                    Console.WriteLine(e.ToString());
                }

                return video;
            }
            finally
            {
                try
                {
                    KillAllFFmpegProcesses();
                    SafeDeleteFile(originalPath);
                    await ForceDeleteDirectoryAsync(hlsPath);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Ошибка при очистке временных файлов: {ex.Message}");
                }
            }
        }
        private void KillAllFFmpegProcesses()
        {
            foreach (var process in Process.GetProcessesByName("ffmpeg"))
            {
                try
                {
                    process.Kill();
                    process.WaitForExit(1000);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Ошибка при завершении FFmpeg: {ex.Message}");
                }
            }
        }
        private void SafeDeleteFile(string path, int retries = 3, int delayMs = 500)
        {
            for (int i = 0; i < retries; i++)
            {
                try
                {
                    if (File.Exists(path))
                    {
                        File.Delete(path);
                        break;
                    }
                }
                catch (IOException)
                {
                    if (i == retries - 1) throw;
                    Thread.Sleep(delayMs);
                }
            }
        }

        private async Task ForceDeleteDirectoryAsync(string path, int retries = 5, int delayMs = 1000)
        {
            if (!Directory.Exists(path))
                return;

            for (int i = 0; i < retries; i++)
            {
                try
                {
                    foreach (var file in Directory.GetFiles(path))
                    {
                        SafeDeleteFile(file, retries: 3, delayMs: 300);
                    }

                    Directory.Delete(path, recursive: true);
                    break;
                }
                catch (IOException ex)
                {
                    if (i == retries - 1)
                        throw new Exception($"Не удалось удалить директорию {path}: {ex.Message}");

                    await Task.Delay(delayMs);
                }
            }
        }
        private async Task EnsureThumbnailBucketExistsAsync()
        {
            var bucketName = "thumbnails";
            var found = await _minioClient.BucketExistsAsync(new BucketExistsArgs().WithBucket(bucketName));
            if (!found)
            {
                await _minioClient.MakeBucketAsync(new MakeBucketArgs().WithBucket(bucketName));

                var policy = new
                {
                    Version = "2012-10-17",
                    Statement = new[]
                    {
                        new
                        {
                            Effect = "Allow",
                            Principal = "*",
                            Action = new[] { "s3:GetObject" },
                            Resource = new[] { $"arn:aws:s3:::{bucketName}/*" }
                        }
                    }
                };

                await _minioClient.SetPolicyAsync(new SetPolicyArgs()
                    .WithBucket(bucketName)
                    .WithPolicy(JsonSerializer.Serialize(policy)));
            }
        }

        public async Task<Stream> GetVideoStreamAsync(string videoUrl)
        {
            var stream = new MemoryStream();
            await _minioClient.GetObjectAsync(
                new GetObjectArgs()
                    .WithBucket(BucketName)
                    .WithObject($"{videoUrl}/master.m3u8")
                    .WithCallbackStream(st => st.CopyTo(stream))
            );
            stream.Position = 0;
            return stream;
        }

        public async Task<string> GetVideoPlaylistAsync(string videoUrl)
        {
            return $"{URL.Url}/videos/{videoUrl}/master.m3u8";
        }

        public async Task<VideoDto> GetVideoMetadataAsync(string videoUrl)
        {
            var video = await _dbContext.Videos.FirstOrDefaultAsync(v => v.VideoUrl == videoUrl);
            var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == video.UserId);
            var meta = new VideoDto
            {
                AvtorId = video.UserId,
                Id = video.Id,
                Description = video.Description,
                LikeCount = video.LikeCount,
                HlsUrl = $"{URL.Url}/videos/{videoUrl}/master.m3u8",
                CommentCount = video.CommentCount,
                ThumbnailUrl = video.ThumbnailUrl,
                AvtorAvatarUrl = $"{URL.Url}/avatars/{user.AvatarUrl}",
                AvtorName = user.UserName
            };
            return meta;
        }

        public async Task<List<VideoDto>> GetUserVideosMetadataAsync(string userId)
        {
            var videos = await _dbContext.Videos
                .Where(v => v.UserId == userId)
                .ToListAsync();
            var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == userId);
            var videosMetadata = videos.Select(video => new VideoDto
            {
                AvtorId = video.UserId,
                Id = video.Id,
                Description = video.Description,
                LikeCount = video.LikeCount,
                HlsUrl = video.VideoUrl,
                CommentCount = video.CommentCount,
                ThumbnailUrl = video.ThumbnailUrl,
                AvtorAvatarUrl = $"{URL.Url}/avatars/{user.AvatarUrl}",
                AvtorName = user.UserName
            }).ToList();

            return videosMetadata;
        }

        public async Task<List<VideoDto>> GetVideosAsync(int page, int limit)
        {
            var query = _dbContext.Videos
                .OrderByDescending(v => v.CreatedAt)
                .Skip((page - 1) * limit)
                .Take(limit)
                .Select(v => new VideoDto
                {
                    AvtorId = v.UserId,
                    Id = v.Id,
                    Description = v.Description,
                    LikeCount = v.LikeCount,
                    HlsUrl = $"{URL.Url}/videos/{v.VideoUrl}/master.m3u8",
                    CommentCount = v.CommentCount,
                    ThumbnailUrl = v.ThumbnailUrl,
                })
                .AsNoTracking();

            return await query.ToListAsync();
        }

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

            process.OutputDataReceived += (sender, e) =>
            {
                if (e.Data != null) output.AppendLine(e.Data);
            };

            process.ErrorDataReceived += (sender, e) =>
            {
                if (e.Data != null) error.AppendLine(e.Data);
            };

            try
            {
                process.Start();
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();

                var timeout = TimeSpan.FromSeconds(60);
                if (!await WaitForExitAsync(process, timeout))
                {
                    process.Kill();
                    throw new TimeoutException($"FFmpeg execution timed out after {timeout.TotalSeconds} seconds");
                }

                if (process.ExitCode != 0)
                {
                    Console.WriteLine("FFmpeg Output:");
                    Console.WriteLine(output.ToString());
                    Console.WriteLine("FFmpeg Error:");
                    Console.WriteLine(error.ToString());

                    throw new Exception($"FFmpeg failed with code {process.ExitCode}. Error: {error}");
                }

                Console.WriteLine("FFmpeg Output:");
                Console.WriteLine(output.ToString());
                Console.WriteLine("FFmpeg Error:");
                Console.WriteLine(error.ToString());

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

