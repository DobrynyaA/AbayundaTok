using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Minio;
using Minio.DataModel.Args;
namespace AbayundaTok.BLL.Interfaces
{
    public interface IMinioService
    {
        Task<string> UploadVideoAsync(IFormFile file, string objectName);
        Task<Stream> GetVideoAsync(string objectName);
    }
}
