from datetime import datetime, timezone

from pydantic import BaseModel, Field


class ProcessRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000)


class ProcessResponse(BaseModel):
    original_message: str
    transformed_message: str
    processed_at: datetime

    @classmethod
    def from_input(cls, message: str) -> "ProcessResponse":
        return cls(
            original_message=message,
            transformed_message=message.upper(),
            processed_at=datetime.now(timezone.utc),
        )
