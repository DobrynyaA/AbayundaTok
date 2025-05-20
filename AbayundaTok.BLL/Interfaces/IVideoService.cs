using AbayundaTok.BLL.DTO;
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
        Task<Video> UploadVideoAsync(IFormFile file, string description, string userId);
        Task<Stream> GetVideoStreamAsync(string videoUrl);
        Task<string> GetVideoPlaylistAsync(string videoUrl);
        Task<VideoDto> GetVideoMetadataAsync(string videoUrl);
        Task<List<VideoDto>> GetVideosAsync(int page, int limit);
        Task<List<VideoDto>> GetUserVideosMetadataAsync(string userId);
    }
}
