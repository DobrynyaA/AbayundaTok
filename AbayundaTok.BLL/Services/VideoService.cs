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

        public async Task<Video> UploadVideoAsync(IFormFile file, string userId)
        {
            await EnsureBucketExistsAsync();

            var videoUrl = Guid.NewGuid().ToString();
            var tempPath = Path.GetTempPath();
            var originalPath = Path.Combine(tempPath, $"{videoUrl}_original.mp4");
            var hlsPath = Path.Combine(tempPath, videoUrl);

            try
            {
                Directory.CreateDirectory(hlsPath);
                await using (var stream = new FileStream(originalPath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                var ffmpegCmd = $"-i \"{originalPath}\" -c:v libx264 -hls_time 10 -hls_list_size 0 \"{Path.Combine(hlsPath, "master.m3u8")}\"";
                await ExecuteFFmpegCommand(ffmpegCmd);

                var chunks = Directory.GetFiles(hlsPath);
                if (chunks.Length == 0)
                {
                    throw new Exception("No HLS chunks were generated");
                }

                foreach (var chunk in chunks)
                {
                    var objectName = $"{videoUrl}/{Path.GetFileName(chunk)}";
                    await _minioClient.PutObjectAsync(
                        new PutObjectArgs()
                            .WithBucket(BucketName)
                            .WithObject(objectName)
                            .WithFileName(chunk)
                    );
                }

                var video = new Video
                {
                    UserId = userId,
                    VideoUrl = videoUrl,
                    Description = "fsdfsdfsdf",
                };

                try
                {
                    _dbContext.Videos.Add(video);
                    await _dbContext.SaveChangesAsync();
                }
                catch(Exception e)
                {
                    Console.WriteLine(e.ToString());
                }
                
                return video;
            }
            finally
            {
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
            var playlistUrl = await _minioClient.PresignedGetObjectAsync(
                new PresignedGetObjectArgs()
                    .WithBucket(BucketName)
                    .WithObject($"{videoUrl}/master.m3u8")
                    .WithExpiry(3600)
            );
            return playlistUrl;
        }

        public async Task<Video> GetVideoMetadataAsync(string videoUrl)
        {
            var meta = new Video
            {
                VideoUrl = videoUrl,
                CreatedAt = DateTime.UtcNow
            };
            return meta;
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

            process.OutputDataReceived += (sender, e) => output.AppendLine(e.Data);
            process.ErrorDataReceived += (sender, e) => error.AppendLine(e.Data);

            try
            {
                process.Start();
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
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

