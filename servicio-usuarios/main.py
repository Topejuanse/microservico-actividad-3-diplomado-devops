from fastapi import FastAPI

app = FastAPI()

@app.get("/db_usuarios/{db_id}")

def get_usuarios(db_id : int):

    return {"servicio": "db_usuarios", "id": db_id, "status": "ok", "datos": ["Jeisson", "Paula", "Danny", "Sebastian"]}