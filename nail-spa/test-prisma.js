import { PrismaClient } from './src/generated/prisma/index.js'; // <--- aquí el cambio

const prisma = new PrismaClient();

async function main() {
  try {
    const juegos = await prisma.juegos.findMany();
    console.log('Conexión exitosa. Juegos:', juegos);
  } catch (error) {
    console.error('Error al conectar:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
