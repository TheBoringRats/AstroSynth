import requests
import json

def fetch_all_exoplanets():
    query = """
    SELECT
      pl_name,
      hostname,
      sy_dist,
      pl_orbper,
      pl_rade,
      pl_bmasse,
      pl_eqt,
      pl_orbsmax,
      pl_orbeccen,
      st_spectype,
      st_teff,
      st_rad,
      st_mass,
      disc_year,
      discoverymethod,
      ra,
      dec,
      default_flag
    FROM ps
    WHERE default_flag = 1
    ORDER BY disc_year DESC
    """.replace("\n", " ").strip()

    base_url = "https://exoplanetarchive.ipac.caltech.edu/TAP/sync"
    params = {"query": query, "format": "json"}
    headers = {
        "Accept": "application/json",
        "User-Agent": "AstroSynth/1.0.0 (NASA Space Apps Challenge)"
    }

    print("🌐 Requesting all exoplanets (~6000 rows)...")
    resp = requests.get(base_url, params=params, headers=headers, timeout=120)

    if resp.status_code != 200:
        raise RuntimeError(f"HTTP {resp.status_code}: {resp.text[:200]}")

    data = resp.json()
    print(f"✅ Got {len(data)} planets")
    return data


def paginate(data, batch_size=100):
    """Yield chunks of data of size batch_size."""
    for i in range(0, len(data), batch_size):
        yield data[i:i + batch_size]


if __name__ == "__main__":
    planets = fetch_all_exoplanets()

    print(f"🌍 Total planets fetched: {len(planets)}")

    # Save full dataset to JSON file
    with open("Exoplanate.json", "w", encoding="utf-8") as f:
        json.dump(planets, f, indent=2, ensure_ascii=False)

    print("💾 Data saved to Exoplanate.json")
