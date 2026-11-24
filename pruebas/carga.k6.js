// Prueba de carga de Online Boutique con k6 (https://k6.io).
//
// Uso:
//   k6 run -e URL=http://<dns-del-alb>/ pruebas/carga.k6.js
//   k6 run -e URL=http://<dns-del-alb>/ -e PICO=150 pruebas/carga.k6.js
//
// Simula un pico de trafico: sube de 0 a PICO usuarios virtuales, lo sostiene y baja.
// Cada usuario navega la portada, un producto y agrega al carrito (usa Redis).
// Los umbrales (thresholds) hacen fallar la prueba si el servicio se degrada.
import http from 'k6/http';
import { check, sleep, group } from 'k6';

const URL = (__ENV.URL || 'http://localhost/').replace(/\/$/, '');
const PICO = parseInt(__ENV.PICO || '100');

const PRODUCTOS = [
  'OLJCESPC7Z', '66VCHSJNUP', '1YMWWN1N4O', 'L9ECAV7KIM', '2ZYFJ3GM2N',
  '0PUK6V6EV0', 'LS4PSXUNUM', '9SIQT8TOJO', '6E92ZMYYFZ',
];

export const options = {
  stages: [
    { duration: '1m', target: Math.round(PICO / 4) }, // calentamiento
    { duration: '1m', target: PICO },                 // subida al pico
    { duration: '3m', target: PICO },                 // pico sostenido
    { duration: '1m', target: 0 },                    // bajada
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],      // menos de 1 % de errores
    http_req_duration: ['p(95)<2000'],   // p95 por debajo de 2 s
  },
};

export default function () {
  group('portada', () => {
    const r = http.get(`${URL}/`);
    check(r, { 'portada 200': (x) => x.status === 200 });
  });
  sleep(1);

  group('producto', () => {
    const id = PRODUCTOS[Math.floor(Math.random() * PRODUCTOS.length)];
    const r = http.get(`${URL}/product/${id}`);
    check(r, { 'producto 200': (x) => x.status === 200 });
  });
  sleep(1);

  group('carrito', () => {
    const id = PRODUCTOS[Math.floor(Math.random() * PRODUCTOS.length)];
    const r = http.post(`${URL}/cart`, { product_id: id, quantity: '1' });
    check(r, { 'carrito 200': (x) => x.status === 200 });
  });
  sleep(1);
}
