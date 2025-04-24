using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AbayundaTok.DAL.Migrations
{
    /// <inheritdoc />
    public partial class AddLikesCountToVideos : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "LikeCount",
                table: "Videos",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LikeCount",
                table: "Videos");
        }
    }
}
