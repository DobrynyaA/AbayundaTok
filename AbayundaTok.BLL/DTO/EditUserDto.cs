using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.DTO
{
    public class EditUserDto
    {
        public string? UserName { get; set; }
        public string? Bio { get; set; }
        public IFormFile? Avatar { get; set; }
    }
}
