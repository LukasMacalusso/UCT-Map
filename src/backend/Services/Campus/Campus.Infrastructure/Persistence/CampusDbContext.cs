using Microsoft.EntityFrameworkCore;
using Campus.Domain.Entities;
using Campus.Domain.ValueObjects;
using CampusEntity = Campus.Domain.Entities.Campus;
using System.Reflection;

namespace Campus.Infrastructure.Persistence
{
    public class CampusDbContext : DbContext
    {
        public CampusDbContext(DbContextOptions<CampusDbContext> options) : base(options)
        {
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
        }

        public DbSet<CampusEntity> Campuses { get; set; }
        public DbSet<Building> Buildings { get; set; }
        public DbSet<Room> Rooms { get; set; }
        public DbSet<Structure> Structures { get; set; }
        public DbSet<Category> Categories { get; set; }
    }
}
