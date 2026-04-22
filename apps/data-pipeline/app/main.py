import logging
import os
import time
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse, Response
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

from app.logging_config import setup_logging
from app.models import ProcessRequest, ProcessResponse

setup_logging()
logger = logging.getLogger("data-pipeline-service")


@asynccontextmanager
async def lifespan(_: FastAPI):
    logger.info("service_starting")
    try:
        yield
    finally:
        logger.info("service_stopping")


app = FastAPI(title="data-pipeline-service", version="1.0.0", lifespan=lifespan)

HTTP_REQUESTS_TOTAL = Counter(
    "http_requests_total",
    "Total number of HTTP requests.",
    ["method", "path", "status_code"],
)

HTTP_REQUEST_DURATION_SECONDS = Histogram(
    "http_request_duration_seconds",
    "HTTP request duration in seconds.",
    ["method", "path", "status_code"],
)


@app.middleware("http")
async def request_context_middleware(request: Request, call_next):
    request_id = request.headers.get("x-request-id", str(uuid.uuid4()))
    request.state.request_id = request_id
    start_time = time.perf_counter()
    status_code = 500

    logger.info(
        "request_started",
        extra={"request_id": request_id, "method": request.method, "path": request.url.path},
    )
    try:
        response = await call_next(request)
        status_code = response.status_code
    except Exception:
        duration_seconds = time.perf_counter() - start_time
        HTTP_REQUESTS_TOTAL.labels(request.method, request.url.path, str(status_code)).inc()
        HTTP_REQUEST_DURATION_SECONDS.labels(request.method, request.url.path, str(status_code)).observe(duration_seconds)
        raise

    response.headers["x-request-id"] = request_id
    logger.info(
        "request_completed",
        extra={
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "status_code": response.status_code,
        },
    )

    duration_seconds = time.perf_counter() - start_time
    HTTP_REQUESTS_TOTAL.labels(request.method, request.url.path, str(status_code)).inc()
    HTTP_REQUEST_DURATION_SECONDS.labels(request.method, request.url.path, str(status_code)).observe(duration_seconds)
    return response


@app.get("/metrics")
async def metrics() -> Response:
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    request_id = getattr(request.state, "request_id", str(uuid.uuid4()))
    logger.warning("validation_error", extra={"request_id": request_id, "errors": exc.errors()})
    return JSONResponse(
        status_code=422,
        content={"detail": exc.errors(), "request_id": request_id},
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    request_id = getattr(request.state, "request_id", str(uuid.uuid4()))
    logger.warning(
        "http_exception",
        extra={"request_id": request_id, "status_code": exc.status_code, "detail": exc.detail},
    )
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail, "request_id": request_id},
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    request_id = getattr(request.state, "request_id", str(uuid.uuid4()))
    logger.exception("unhandled_exception", extra={"request_id": request_id})
    return JSONResponse(
        status_code=500,
        content={"detail": "internal_server_error", "request_id": request_id},
    )


@app.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/process", response_model=ProcessResponse)
async def process(payload: ProcessRequest, request: Request) -> ProcessResponse:
    request_id = getattr(request.state, "request_id", str(uuid.uuid4()))
    logger.info("processing_payload", extra={"request_id": request_id})

    if not payload.message.strip():
        raise HTTPException(status_code=400, detail="message must not be blank")

    return ProcessResponse.from_input(payload.message)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", "8000")),
        log_config=None,
        access_log=False,
    )
