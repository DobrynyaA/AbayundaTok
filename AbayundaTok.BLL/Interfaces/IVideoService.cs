using Diplom.DAL.Entities;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.Interfaces
{
    public interface IVideoService
    {
        Task<string> UploadVideoAsync(IFormFile file, string videoName);
        Task<Stream> GetVideoStreamAsync(int videoId);
        Task<string> GetVideoPlaylistAsync(int videoId);
        //Task DeleteVideoAsync(string videoId);
        Task<Video> GetVideoMetadataAsync(int videoId);
    }
}
