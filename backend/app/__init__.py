import os
from dotenv import load_dotenv

dotenv_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), '.env')
load_dotenv(dotenv_path)

print("✅ SECRET_KEY loaded globally:", os.getenv("SECRET_KEY"))
