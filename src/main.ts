import "reflect-metadata";
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";
import { Logger } from "@nestjs/common";

const DEFAULT_PORT = 3000;
const DEFAULT_FRONTEND_ORIGIN = "http://localhost:3000";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix("api");

  app.enableCors({
    origin: process.env.FRONTEND_ORIGIN || DEFAULT_FRONTEND_ORIGIN,
    methods: "GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS",
    allowedHeaders: "Content-Type, Authorization",
  });

  const port = process.env.PORT || DEFAULT_PORT;
  await app.listen(port);
  Logger.log(`Backend running on http://localhost:${port}/api`, "Bootstrap");
}

bootstrap();

