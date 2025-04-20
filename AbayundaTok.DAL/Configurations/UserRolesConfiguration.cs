using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Diplom.DAL.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Diplom.DAL.Configurations
{
    public class UserRolesConfiguration : IEntityTypeConfiguration<UsersRoles>
    {
        public void Configure(EntityTypeBuilder<UsersRoles> builder)
        {
            builder.HasNoKey();
        }
    }
}
