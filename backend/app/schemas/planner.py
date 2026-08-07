from pydantic import BaseModel

class PlannerRequest(BaseModel):
    destination: str
    days: int
    budget: int


class PlannerResponse(BaseModel):
    destination: str
    itinerary: list[str]
    estimated_budget: int