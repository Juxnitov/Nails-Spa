import { PrismaClient } from '../../generated/prisma';

const prisma = new PrismaClient();

export default async function handler(req, res) {
  if (req.method === 'GET') {
    const juegos = await prisma.juegos.findMany();
    res.status(200).json(juegos);
  } else if (req.method === 'POST') {
    const { nombre, precio, stock, descripcion } = req.body;
    const nuevoJuego = await prisma.juegos.create({
      data: { nombre, precio, stock, descripcion },
    });
    res.status(201).json(nuevoJuego);
  } else {
    res.status(405).json({ message: 'Method not allowed' });
  }
}
