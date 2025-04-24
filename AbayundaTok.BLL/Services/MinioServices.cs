using AbayundaTok.BLL.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Minio;
using Minio.DataModel.Args;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.Services
{
    public class MinioService : IMinioService
    {
        private readonly IMinioClient _minioClient;
        private readonly string _bucketName;

        public MinioService(IConfiguration config)
        {
            var minioConfig = config.GetSection("MinIO");
            _minioClient = new MinioClient()
                .WithEndpoint(minioConfig["Endpoint"])
                .WithCredentials(minioConfig["AccessKey"], minioConfig["SecretKey"])
                .WithSSL(bool.Parse(minioConfig["UseSSL"]))
                .Build();
            _bucketName = minioConfig["BucketName"];
        }

        public async Task<string> UploadVideoAsync(IFormFile file, string objectName)
        {
            var putObdjnjectArgs = new PutObjectArgs()
                .WithBucket(_bucketName)
                .WithObject(objectName)
                .WithStreamData(file.OpenReadStream())
                .WithObjectSize(file.Length)
                .WithContentType(file.ContentType);

            await _minioClient.PutObjectAsync(putObdjnjectArgs);
            return objectName;
        }

        public async Task<Stream> GetVideoAsync(string objectName)
        {
            var stream = new MemoryStream();
            var args = new GetObjectArgs()
                .WithBucket(_bucketName)
                .WithObject(objectName)
                .WithCallbackStream(stream => stream.CopyToAsync(stream));

            await _minioClient.GetObjectAsync(args);
            stream.Position = 0;
            return stream;
        }
    }
}
