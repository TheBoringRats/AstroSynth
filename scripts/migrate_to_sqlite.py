#!/usr/bin/env python3
"""
Script to migrate exoplanet data from JSON to SQLite database.
This improves query performance for 6022+ planets.
"""

import json
import sqlite3
import sys
from pathlib import Path

def create_database(db_path):
    """Create SQLite database with optimized schema for planet data."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Drop existing table if it exists
    cursor.execute('DROP TABLE IF EXISTS planets')

    # Create planets table with all NASA fields
    cursor.execute('''
        CREATE TABLE planets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pl_name TEXT NOT NULL UNIQUE,
            hostname TEXT,
            sy_dist REAL,
            pl_orbper REAL,
            pl_rade REAL,
            pl_bmasse REAL,
            pl_eqt REAL,
            pl_orbsmax REAL,
            pl_orbeccen REAL,
            st_spectype TEXT,
            st_teff REAL,
            st_rad REAL,
            st_mass REAL,
            disc_year INTEGER,
            discoverymethod TEXT,
            ra REAL,
            dec REAL,
            default_flag INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # Create indexes for faster queries
    cursor.execute('CREATE INDEX idx_pl_name ON planets(pl_name)')
    cursor.execute('CREATE INDEX idx_disc_year ON planets(disc_year)')
    cursor.execute('CREATE INDEX idx_discoverymethod ON planets(discoverymethod)')
    cursor.execute('CREATE INDEX idx_pl_rade ON planets(pl_rade)')
    cursor.execute('CREATE INDEX idx_pl_bmasse ON planets(pl_bmasse)')
    cursor.execute('CREATE INDEX idx_st_teff ON planets(st_teff)')
    cursor.execute('CREATE INDEX idx_sy_dist ON planets(sy_dist)')

    conn.commit()
    return conn

def migrate_json_to_sqlite(json_path, db_path):
    """Migrate planet data from JSON to SQLite."""
    print(f'[MIGRATE] Reading JSON from: {json_path}')

    # Load JSON data
    with open(json_path, 'r', encoding='utf-8') as f:
        planets = json.load(f)

    print(f'[MIGRATE] Loaded {len(planets)} planets from JSON')

    # Create database
    print(f'[MIGRATE] Creating SQLite database: {db_path}')
    conn = create_database(db_path)
    cursor = conn.cursor()

    # Insert planets in batches
    batch_size = 100
    inserted = 0
    skipped = 0

    for i in range(0, len(planets), batch_size):
        batch = planets[i:i + batch_size]

        for planet in batch:
            try:
                cursor.execute('''
                    INSERT INTO planets (
                        pl_name, hostname, sy_dist, pl_orbper, pl_rade,
                        pl_bmasse, pl_eqt, pl_orbsmax, pl_orbeccen,
                        st_spectype, st_teff, st_rad, st_mass,
                        disc_year, discoverymethod, ra, dec, default_flag
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    planet.get('pl_name'),
                    planet.get('hostname'),
                    planet.get('sy_dist'),
                    planet.get('pl_orbper'),
                    planet.get('pl_rade'),
                    planet.get('pl_bmasse'),
                    planet.get('pl_eqt'),
                    planet.get('pl_orbsmax'),
                    planet.get('pl_orbeccen'),
                    planet.get('st_spectype'),
                    planet.get('st_teff'),
                    planet.get('st_rad'),
                    planet.get('st_mass'),
                    planet.get('disc_year'),
                    planet.get('discoverymethod'),
                    planet.get('ra'),
                    planet.get('dec'),
                    planet.get('default_flag', 1)
                ))
                inserted += 1
            except sqlite3.IntegrityError as e:
                skipped += 1
                if skipped <= 5:
                    print(f'[WARNING] Skipped duplicate: {planet.get("pl_name")} - {e}')
            except Exception as e:
                skipped += 1
                if skipped <= 5:
                    print(f'[ERROR] Failed to insert {planet.get("pl_name")}: {e}')

        conn.commit()
        print(f'[PROGRESS] Inserted: {inserted}/{len(planets)} (skipped: {skipped})')

    # Verify data
    cursor.execute('SELECT COUNT(*) FROM planets')
    count = cursor.fetchone()[0]

    print(f'\n[SUCCESS] Migration complete!')
    print(f'[SUCCESS] Total planets in database: {count}')
    print(f'[SUCCESS] Inserted: {inserted}, Skipped: {skipped}')

    # Show some statistics
    cursor.execute('SELECT discoverymethod, COUNT(*) FROM planets GROUP BY discoverymethod ORDER BY COUNT(*) DESC LIMIT 5')
    methods = cursor.fetchall()
    print(f'\n[STATS] Top discovery methods:')
    for method, count in methods:
        print(f'  - {method}: {count} planets')

    cursor.execute('SELECT MIN(disc_year), MAX(disc_year) FROM planets WHERE disc_year IS NOT NULL')
    min_year, max_year = cursor.fetchone()
    print(f'\n[STATS] Discovery years: {min_year} - {max_year}')

    conn.close()
    print(f'\n[DONE] Database saved to: {db_path}')

def main():
    # Paths
    project_root = Path(__file__).parent.parent
    json_path = project_root / 'assets' / 'data' / 'Exoplanet_FULL.json'
    db_path = project_root / 'assets' / 'data' / 'exoplanets.db'

    print('[INFO] Starting JSON to SQLite migration...')
    print(f'[INFO] Project root: {project_root}')
    print(f'[INFO] JSON file: {json_path}')
    print(f'[INFO] Database file: {db_path}')
    print()

    # Check if JSON exists
    if not json_path.exists():
        print(f'[ERROR] JSON file not found: {json_path}')
        sys.exit(1)

    # Run migration
    try:
        migrate_json_to_sqlite(json_path, db_path)
    except Exception as e:
        print(f'[ERROR] Migration failed: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()
