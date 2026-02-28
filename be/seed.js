const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const defaultCategories = [
    'Makan & Minum',
    'Transportasi',
    'Belanja',
    'Tagihan & Utilitas',
    'Hiburan',
    'Kesehatan',
    'Pendidikan',
    'Gaji',
    'Bisnis',
    'Lainnya'
  ];

  console.log('Mulai membuat seed kategory...');
  for (const name of defaultCategories) {
    const existing = await prisma.category.findFirst({ where: { name } });
    if (!existing) {
      const category = await prisma.category.create({
        data: { name },
      });
      console.log(`Berhasil membuat kategori: ${category.name}`);
    } else {
      console.log(`Kategori sudah ada: ${existing.name}`);
    }
  }
  console.log('Seeding selesai!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
