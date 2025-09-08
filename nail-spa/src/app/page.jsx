"use client";
import { useEffect, useState } from "react";

export default function Home() {
  const [juegos, setJuegos] = useState([]);

  useEffect(() => {
    fetch("/api/juegos")
      .then(res => res.json())
      .then(data => setJuegos(data));
  }, []);

  return (
    <div style={{ padding: "2rem" }}>
      <h1>Tienda de Juegos Exclusivos</h1>
      <div style={{ display: "flex", flexWrap: "wrap", gap: "1rem" }}>
        {juegos.map(j => (
          <div
            key={j.juego_id}
            style={{
              border: "1px solid #ccc",
              padding: "1rem",
              borderRadius: "8px",
              width: "200px",
            }}
          >
            <h2>{j.titulo}</h2>
            <p>{j.descripcion}</p>
            <p><strong>${j.precio}</strong></p>
            <p>Stock: {j.stock}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
