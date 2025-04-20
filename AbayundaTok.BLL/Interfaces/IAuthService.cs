using AbayundaTok.BLL.DTO;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.Interfaces
{
    public interface IAuthService
    {
        public Task<AuthResponseDto> LoginAsync(LoginDto loginDto);
        public Task<AuthResponseDto> RegisterAsync(RegisterDto registerDto);
    }
}
