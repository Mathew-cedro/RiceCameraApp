import cv2 as cv
import numpy as np
from fastapi import FastAPI, UploadFile, File
import uvicorn

app = FastAPI()

@app.get("/")
async def test_route():
    return {"status": "Server is alive and reachable!"}


@app.post("/analyze")
async def analyze_palay(file: UploadFile = File(...)):
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    img = cv.imdecode(nparr, cv.IMREAD_COLOR)
    print("analyzing")
    
    # Resizes image
    h, w = img.shape[:2]
    img = cv.resize(img, (400, int(h * (400 / w))))
    hsv = cv.cvtColor(img, cv.COLOR_BGR2HSV)

    # Define Masks needed for identifying the  color ranges
    yellow_mask = cv.inRange(hsv, np.array([15, 100, 100]), np.array([35, 255, 255]))
    brown_mask = cv.inRange(hsv, np.array([10, 50, 50]), np.array([20, 255, 200]))
    plant_mask = cv.inRange(hsv, np.array([10, 30, 30]), np.array([90, 255, 255]))
    ripe_mask = cv.bitwise_or(yellow_mask, brown_mask)
    total_plant_pixels = cv.countNonZero(plant_mask)
    if total_plant_pixels == 0: total_plant_pixels = 1 

    # Calculate Counts
    ripe_count = cv.countNonZero(ripe_mask)
    yellow_count = cv.countNonZero(yellow_mask)
    brown_count = cv.countNonZero(brown_mask)

    # Calculate Percentages and CLAMP them to 100.0 max
    ripe_pct = min(100.0, (ripe_count / total_plant_pixels) * 100)
    yellow_pct = min(100.0, (yellow_count / total_plant_pixels) * 100)
    brown_pct = min(100.0, (brown_count / total_plant_pixels) * 100)

    # Logic for status
    if ripe_pct >= 70:
        res = ["Fully Ripe", "Ready to harvest now!", "#4CAF50", "check"]
    elif ripe_pct >= 40:
        res = ["Nearly Harvestable", "A few more days before optimal harvest.", "#8BC34A", "time"]
    elif ripe_pct >= 20:
        res = ["Barely Harvestable", "Still maturing — monitor closely.", "#FF9800", "hourglass"]
    else:
        res = ["Not Harvestable", "Crop is still green. Not ready yet.", "#F44336", "cancel"]

    # Returns the stats back to the front end
    print(f"Finished: {res[0]}")
    return {
        "status": res[0],
        "advice": res[1],
        "ripePercent": round(ripe_pct, 2),
        "yellowPercent": round(yellow_pct, 2),
        "brownPercent": round(brown_pct, 2),
        "statusColor": res[2],
        "iconType": res[3]
    }

if __name__ == "__main__":
    uvicorn.run(app, host="10.0.0.12", port=8000)