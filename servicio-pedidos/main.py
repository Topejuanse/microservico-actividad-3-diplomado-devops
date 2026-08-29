from fastapi import FastAPI

app = FastAPI()

@app.get("/pedidos")

def get_pedidos():

    return {"servicio": "pedidos", "status": "ok", "data": ["Articulo #1", "Articulo #2", "Articulo #3"]}