using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AbayundaTok.DAL.Migrations
{
    /// <inheritdoc />
    public partial class Add_CommentCount_And_Delete_ViewCount : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "ViewCount",
                table: "Videos",
                newName: "CommentCount");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "CommentCount",
                table: "Videos",
                newName: "ViewCount");
        }
    }
}
