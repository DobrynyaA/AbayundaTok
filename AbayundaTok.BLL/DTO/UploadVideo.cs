using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.DTO
{
    public class UploadVideo
    {
        public string? Description { get; set; }
        public IFormFile VideoFile { get; set; }
    }
}
