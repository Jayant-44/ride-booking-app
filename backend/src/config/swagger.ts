import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';
import path from 'path';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Ride Booking API',
      version: '1.0.0',
      description: 'Ride Booking App API Documentation',
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Development server',
      },
    ],
  },
  apis: [
    path.join(process.cwd(), 'src/modules/**/*.ts'), 
    path.join(process.cwd(), 'dist/modules/**/*.js')
  ], 
};

const specs = swaggerJsdoc(options);

export { swaggerUi, specs };