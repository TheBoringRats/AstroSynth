// Animated Planet Renderer using Anime.js
// Generates unique, real-time animated planets based on exoplanet data

class AnimatedPlanetRenderer {
  constructor(canvasId, planetData) {
    this.canvas = document.getElementById(canvasId);
    if (!this.canvas) {
      console.error(`Canvas with id ${canvasId} not found`);
      return;
    }

    this.ctx = this.canvas.getContext("2d");
    this.planetData = planetData;
    this.width = this.canvas.width;
    this.height = this.canvas.height;
    this.centerX = this.width / 2;
    this.centerY = this.height / 2;

    // Animation state
    this.rotation = 0;
    this.atmosphereOpacity = 0.3;
    this.glowIntensity = 0.5;
    this.craterOpacity = 0.7;

    // Planet properties derived from data
    this.radius = this.width * 0.35;
    this.colors = this.calculateColors();
    this.features = this.determineFeatures();

    // Initialize animations
    this.initAnimations();
    this.render();
  }

  calculateColors() {
    const { temperature, mass, density, biome } = this.planetData;
    const temp = temperature || 300;
    const uniqueSeed = this.hashCode(this.planetData.name) % 100;

    // Base colors by biome type
    const biomeColors = {
      "Gas Giant": { h: 270, s: 70, l: 50 },
      "Ice Giant": { h: 200, s: 60, l: 60 },
      "Super Earth": { h: 140, s: 50, l: 45 },
      "Mini Neptune": { h: 180, s: 55, l: 55 },
      "Rocky Planet": { h: 25, s: 40, l: 40 },
      "Ice World": { h: 190, s: 50, l: 70 },
      "Lava World": { h: 15, s: 90, l: 50 },
      "Ocean World": { h: 210, s: 80, l: 45 },
      "Desert World": { h: 40, s: 70, l: 55 },
      "Barren World": { h: 0, s: 0, l: 35 },
    };

    let baseColor = biomeColors[biome] || { h: 200, s: 50, l: 50 };

    // Temperature modifications
    let hueShift = 0;
    let satMod = 1.0;
    let lightMod = 1.0;

    if (temp > 1500) {
      hueShift = -20 + (uniqueSeed % 10);
      satMod = 0.7;
      lightMod = 1.3;
    } else if (temp > 800) {
      hueShift = -10 + (uniqueSeed % 15);
      satMod = 0.9;
      lightMod = 1.1;
    } else if (temp > 400) {
      hueShift = -5 + (uniqueSeed % 10);
      satMod = 0.95;
      lightMod = 1.05;
    } else if (temp < 100) {
      hueShift = 10 + (uniqueSeed % 15);
      satMod = 0.6;
      lightMod = 0.9;
    } else if (temp < 200) {
      hueShift = 5 + (uniqueSeed % 10);
      satMod = 0.8;
      lightMod = 0.95;
    } else {
      hueShift = -10 + (uniqueSeed % 20);
      satMod = 0.9 + uniqueSeed / 500;
      lightMod = 0.95 + uniqueSeed / 200;
    }

    // Mass modifications
    if (mass > 10) {
      lightMod *= 0.85;
      satMod *= 1.1;
    } else if (mass > 5) {
      lightMod *= 0.9;
      satMod *= 1.05;
    } else if (mass < 0.5) {
      lightMod *= 1.1;
      satMod *= 0.9;
    }

    // Density modifications
    const dens = density || mass / Math.pow(this.planetData.radius || 1, 2);
    if (dens > 2) {
      satMod *= 1.15;
      lightMod *= 0.95;
    } else if (dens < 0.5) {
      satMod *= 0.85;
      lightMod *= 1.05;
    }

    // Apply modifications
    const finalH = (baseColor.h + hueShift + 360) % 360;
    const finalS = Math.min(100, Math.max(0, baseColor.s * satMod));
    const finalL = Math.min(100, Math.max(0, baseColor.l * lightMod));

    return {
      primary: `hsl(${finalH}, ${finalS}%, ${finalL}%)`,
      secondary: `hsl(${(finalH + 20) % 360}, ${finalS * 0.8}%, ${
        finalL * 1.1
      }%)`,
      tertiary: `hsl(${(finalH - 20 + 360) % 360}, ${finalS * 0.9}%, ${
        finalL * 0.9
      }%)`,
      atmosphere: `hsla(${finalH}, ${finalS}%, ${finalL + 10}%, 0.3)`,
    };
  }

  determineFeatures() {
    const { temperature, mass, biome } = this.planetData;
    const temp = temperature || 300;
    const isGasGiant =
      mass > 0.5 && (biome === "Gas Giant" || biome === "Ice Giant");

    return {
      hasRings: mass > 5 && Math.random() > 0.7,
      hasBands: isGasGiant,
      hasCraters: !isGasGiant && temp > 200 && temp < 600,
      hasLavaCracks: temp > 800,
      hasIceCrystals: temp < 150,
      hasOceanWaves: biome === "Ocean World",
      hasDunes: biome === "Desert World",
      hasStorm: isGasGiant && Math.random() > 0.6,
      hasAtmosphere: mass > 0.3,
      cloudDensity: isGasGiant ? 0.8 : mass > 0.5 ? 0.4 : 0.1,
    };
  }

  hashCode(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = (hash << 5) - hash + char;
      hash = hash & hash;
    }
    return Math.abs(hash);
  }

  initAnimations() {
    // Continuous rotation
    anime({
      targets: this,
      rotation: 360,
      duration: 20000 + (this.hashCode(this.planetData.name) % 10000),
      easing: "linear",
      loop: true,
    });

    // Pulsing atmosphere
    anime({
      targets: this,
      atmosphereOpacity: [0.2, 0.5],
      duration: 3000,
      direction: "alternate",
      easing: "easeInOutSine",
      loop: true,
    });

    // Glow intensity variation
    anime({
      targets: this,
      glowIntensity: [0.3, 0.7],
      duration: 2000 + (this.hashCode(this.planetData.name) % 1000),
      direction: "alternate",
      easing: "easeInOutQuad",
      loop: true,
    });

    // Crater opacity (subtle breathing effect)
    if (this.features.hasCraters) {
      anime({
        targets: this,
        craterOpacity: [0.5, 0.9],
        duration: 4000,
        direction: "alternate",
        easing: "easeInOutSine",
        loop: true,
      });
    }
  }

  render() {
    this.ctx.clearRect(0, 0, this.width, this.height);

    // Draw space background with stars
    this.drawStars();

    // Draw planet glow
    if (this.features.hasAtmosphere) {
      this.drawGlow();
    }

    // Draw main planet sphere
    this.drawPlanetSphere();

    // Draw features based on planet type
    if (this.features.hasBands) this.drawBands();
    if (this.features.hasStorm) this.drawStorm();
    if (this.features.hasCraters) this.drawCraters();
    if (this.features.hasLavaCracks) this.drawLavaCracks();
    if (this.features.hasIceCrystals) this.drawIceCrystals();
    if (this.features.hasOceanWaves) this.drawOceanWaves();
    if (this.features.hasDunes) this.drawDunes();

    // Draw atmosphere
    if (this.features.hasAtmosphere) {
      this.drawAtmosphere();
    }

    // Draw rings if present
    if (this.features.hasRings) {
      this.drawRings();
    }

    // Continue animation loop
    requestAnimationFrame(() => this.render());
  }

  drawStars() {
    const seed = this.hashCode(this.planetData.name);
    for (let i = 0; i < 15; i++) {
      const x = (seed + i * 73) % this.width;
      const y = (seed + i * 97) % this.height;
      const size = 0.5 + (i % 3) * 0.5;

      this.ctx.fillStyle = `rgba(255, 255, 255, ${0.3 + (i % 5) * 0.1})`;
      this.ctx.beginPath();
      this.ctx.arc(x, y, size, 0, Math.PI * 2);
      this.ctx.fill();
    }
  }

  drawGlow() {
    const gradient = this.ctx.createRadialGradient(
      this.centerX,
      this.centerY,
      this.radius * 0.8,
      this.centerX,
      this.centerY,
      this.radius * 1.5
    );

    gradient.addColorStop(0, "rgba(0, 0, 0, 0)");
    gradient.addColorStop(
      0.7,
      this.colors.atmosphere.replace("0.3", String(this.glowIntensity * 0.3))
    );
    gradient.addColorStop(1, "rgba(0, 0, 0, 0)");

    this.ctx.fillStyle = gradient;
    this.ctx.beginPath();
    this.ctx.arc(this.centerX, this.centerY, this.radius * 1.5, 0, Math.PI * 2);
    this.ctx.fill();
  }

  drawPlanetSphere() {
    // Main gradient sphere
    const gradient = this.ctx.createRadialGradient(
      this.centerX - this.radius * 0.3,
      this.centerY - this.radius * 0.3,
      this.radius * 0.1,
      this.centerX,
      this.centerY,
      this.radius
    );

    gradient.addColorStop(0, this.colors.secondary);
    gradient.addColorStop(0.5, this.colors.primary);
    gradient.addColorStop(1, this.colors.tertiary);

    this.ctx.fillStyle = gradient;
    this.ctx.beginPath();
    this.ctx.arc(this.centerX, this.centerY, this.radius, 0, Math.PI * 2);
    this.ctx.fill();

    // Shadow (terminator)
    const shadowGradient = this.ctx.createRadialGradient(
      this.centerX + this.radius * 0.4,
      this.centerY,
      this.radius * 0.1,
      this.centerX + this.radius * 0.4,
      this.centerY,
      this.radius * 0.9
    );

    shadowGradient.addColorStop(0, "rgba(0, 0, 0, 0)");
    shadowGradient.addColorStop(1, "rgba(0, 0, 0, 0.4)");

    this.ctx.fillStyle = shadowGradient;
    this.ctx.beginPath();
    this.ctx.arc(this.centerX, this.centerY, this.radius, 0, Math.PI * 2);
    this.ctx.fill();
  }

  drawBands() {
    const seed = this.hashCode(this.planetData.name);
    const numBands = 3 + (seed % 3);

    this.ctx.save();
    this.ctx.beginPath();
    this.ctx.arc(this.centerX, this.centerY, this.radius, 0, Math.PI * 2);
    this.ctx.clip();

    for (let i = 0; i < numBands; i++) {
      const y =
        this.centerY -
        this.radius +
        ((i + 1) / (numBands + 1)) * (this.radius * 2);
      const height = this.radius * 0.15;
      const offset = Math.sin(((this.rotation + i * 30) * Math.PI) / 180) * 5;

      this.ctx.fillStyle = `rgba(0, 0, 0, ${0.15 + (i % 2) * 0.1})`;
      this.ctx.fillRect(0, y + offset, this.width, height);

      this.ctx.fillStyle = `rgba(255, 255, 255, ${0.05 + (i % 2) * 0.05})`;
      this.ctx.fillRect(0, y + offset + height * 0.5, this.width, 2);
    }

    this.ctx.restore();
  }

  drawStorm() {
    const seed = this.hashCode(this.planetData.name);
    const stormX = this.centerX + ((seed % 40) - 20);
    const stormY = this.centerY + (((seed * 7) % 40) - 20);
    const rotation = this.rotation * 0.5;

    this.ctx.save();
    this.ctx.translate(stormX, stormY);
    this.ctx.rotate((rotation * Math.PI) / 180);

    this.ctx.fillStyle = `rgba(200, 50, 50, 0.3)`;
    this.ctx.beginPath();
    this.ctx.ellipse(
      0,
      0,
      this.radius * 0.25,
      this.radius * 0.15,
      0,
      0,
      Math.PI * 2
    );
    this.ctx.fill();

    this.ctx.fillStyle = `rgba(255, 100, 100, 0.2)`;
    this.ctx.beginPath();
    this.ctx.ellipse(
      0,
      0,
      this.radius * 0.15,
      this.radius * 0.1,
      0,
      0,
      Math.PI * 2
    );
    this.ctx.fill();

    this.ctx.restore();
  }

  drawCraters() {
    const seed = this.hashCode(this.planetData.name);
    const numCraters = 5 + (seed % 4);

    this.ctx.save();
    this.ctx.globalAlpha = this.craterOpacity;

    for (let i = 0; i < numCraters; i++) {
      const angle = (((seed + i * 137) % 360) * Math.PI) / 180;
      const dist = (((seed + i * 73) % 60) * this.radius) / 100;
      const x = this.centerX + Math.cos(angle) * dist;
      const y = this.centerY + Math.sin(angle) * dist;
      const size = 3 + ((seed + i) % 6);

      // Crater rim
      this.ctx.fillStyle = "rgba(0, 0, 0, 0.3)";
      this.ctx.beginPath();
      this.ctx.arc(x, y, size, 0, Math.PI * 2);
      this.ctx.fill();

      // Crater highlight
      this.ctx.fillStyle = "rgba(255, 255, 255, 0.1)";
      this.ctx.beginPath();
      this.ctx.arc(x - size * 0.2, y - size * 0.2, size * 0.7, 0, Math.PI * 2);
      this.ctx.fill();
    }

    this.ctx.restore();
  }

  drawLavaCracks() {
    const seed = this.hashCode(this.planetData.name);
    const numCracks = 5;
    const pulseIntensity =
      0.5 + Math.sin((this.rotation * Math.PI) / 180) * 0.3;

    this.ctx.save();
    this.ctx.strokeStyle = `rgba(255, 100, 0, ${0.6 * pulseIntensity})`;
    this.ctx.lineWidth = 2;
    this.ctx.shadowBlur = 10;
    this.ctx.shadowColor = "rgba(255, 100, 0, 0.8)";

    for (let i = 0; i < numCracks; i++) {
      const angle = ((i * (360 / numCracks) + (seed % 60)) * Math.PI) / 180;
      const startDist = this.radius * 0.2;
      const endDist = this.radius * 0.9;

      this.ctx.beginPath();
      this.ctx.moveTo(
        this.centerX + Math.cos(angle) * startDist,
        this.centerY + Math.sin(angle) * startDist
      );

      for (let j = 0; j < 5; j++) {
        const dist = startDist + (endDist - startDist) * (j / 5);
        const wobble = Math.sin(j + this.rotation * 0.1) * 5;
        this.ctx.lineTo(
          this.centerX + Math.cos(angle) * dist + wobble,
          this.centerY + Math.sin(angle) * dist + wobble
        );
      }

      this.ctx.stroke();
    }

    this.ctx.restore();
  }

  drawIceCrystals() {
    const seed = this.hashCode(this.planetData.name);
    const numCrystals = 8;

    this.ctx.save();
    this.ctx.strokeStyle = `rgba(200, 230, 255, ${
      0.6 + this.glowIntensity * 0.3
    })`;
    this.ctx.lineWidth = 1;
    this.ctx.shadowBlur = 5;
    this.ctx.shadowColor = "rgba(200, 230, 255, 0.8)";

    for (let i = 0; i < numCrystals; i++) {
      const angle = (((seed + i * 137) % 360) * Math.PI) / 180;
      const dist = (((seed + i * 73) % 70) * this.radius) / 100;
      const x = this.centerX + Math.cos(angle) * dist;
      const y = this.centerY + Math.sin(angle) * dist;
      const size = 4 + ((seed + i) % 4);
      const rotationOffset = (this.rotation + i * 45) % 360;

      this.ctx.save();
      this.ctx.translate(x, y);
      this.ctx.rotate((rotationOffset * Math.PI) / 180);

      // Draw 6-pointed crystal
      for (let j = 0; j < 6; j++) {
        const crystalAngle = (j * 60 * Math.PI) / 180;
        this.ctx.beginPath();
        this.ctx.moveTo(0, 0);
        this.ctx.lineTo(
          Math.cos(crystalAngle) * size,
          Math.sin(crystalAngle) * size
        );
        this.ctx.stroke();
      }

      this.ctx.restore();
    }

    this.ctx.restore();
  }

  drawOceanWaves() {
    const numWaves = 4;

    this.ctx.save();
    this.ctx.strokeStyle = `rgba(0, 100, 200, 0.2)`;
    this.ctx.lineWidth = 1.5;

    for (let i = 0; i < numWaves; i++) {
      const baseRadius = this.radius * (0.3 + i * 0.15);
      const points = 12;

      this.ctx.beginPath();
      for (let j = 0; j <= points; j++) {
        const angle = (j / points) * Math.PI * 2;
        const waveOffset = Math.sin(angle * 3 + this.rotation * 0.02 + i) * 5;
        const r = baseRadius + waveOffset;
        const x = this.centerX + Math.cos(angle) * r;
        const y = this.centerY + Math.sin(angle) * r;

        if (j === 0) {
          this.ctx.moveTo(x, y);
        } else {
          this.ctx.lineTo(x, y);
        }
      }
      this.ctx.stroke();
    }

    this.ctx.restore();
  }

  drawDunes() {
    const numDunes = 5;
    const seed = this.hashCode(this.planetData.name);

    this.ctx.save();
    this.ctx.beginPath();
    this.ctx.arc(this.centerX, this.centerY, this.radius, 0, Math.PI * 2);
    this.ctx.clip();

    this.ctx.strokeStyle = `rgba(180, 140, 60, 0.25)`;
    this.ctx.lineWidth = 2;

    for (let i = 0; i < numDunes; i++) {
      const startY =
        this.centerY -
        this.radius +
        ((i + 1) / (numDunes + 1)) * (this.radius * 2);

      this.ctx.beginPath();
      for (let j = 0; j < 20; j++) {
        const x = (j / 20) * this.width;
        const y = startY + Math.sin(j * 0.8 + seed + this.rotation * 0.01) * 5;

        if (j === 0) {
          this.ctx.moveTo(x, y);
        } else {
          this.ctx.lineTo(x, y);
        }
      }
      this.ctx.stroke();
    }

    this.ctx.restore();
  }

  drawAtmosphere() {
    if (!this.features.hasAtmosphere) return;

    const gradient = this.ctx.createRadialGradient(
      this.centerX,
      this.centerY,
      this.radius * 0.9,
      this.centerX,
      this.centerY,
      this.radius * 1.1
    );

    gradient.addColorStop(0, "rgba(0, 0, 0, 0)");
    gradient.addColorStop(
      0.5,
      this.colors.atmosphere.replace("0.3", String(this.atmosphereOpacity))
    );
    gradient.addColorStop(1, "rgba(0, 0, 0, 0)");

    this.ctx.fillStyle = gradient;
    this.ctx.beginPath();
    this.ctx.arc(this.centerX, this.centerY, this.radius * 1.1, 0, Math.PI * 2);
    this.ctx.fill();
  }

  drawRings() {
    const ringInnerRadius = this.radius * 1.2;
    const ringOuterRadius = this.radius * 1.8;

    this.ctx.save();
    this.ctx.strokeStyle = this.colors.tertiary
      .replace("hsl", "hsla")
      .replace(")", ", 0.4)");
    this.ctx.lineWidth = 3;

    // Draw elliptical ring (perspective view)
    this.ctx.beginPath();
    this.ctx.ellipse(
      this.centerX,
      this.centerY,
      ringOuterRadius,
      ringOuterRadius * 0.25,
      0,
      0,
      Math.PI * 2
    );
    this.ctx.stroke();

    // Inner ring
    this.ctx.strokeStyle = this.colors.tertiary
      .replace("hsl", "hsla")
      .replace(")", ", 0.2)");
    this.ctx.lineWidth = 2;
    this.ctx.beginPath();
    this.ctx.ellipse(
      this.centerX,
      this.centerY,
      ringInnerRadius,
      ringInnerRadius * 0.25,
      0,
      0,
      Math.PI * 2
    );
    this.ctx.stroke();

    this.ctx.restore();
  }
}

// Global registry of planet renderers
window.planetRenderers = window.planetRenderers || {};

// Function to create and register a planet renderer
window.createPlanetRenderer = function (canvasId, planetData) {
  if (window.planetRenderers[canvasId]) {
    // Clean up existing renderer if any
    delete window.planetRenderers[canvasId];
  }

  window.planetRenderers[canvasId] = new AnimatedPlanetRenderer(
    canvasId,
    planetData
  );
  return window.planetRenderers[canvasId];
};

// Function to destroy a planet renderer
window.destroyPlanetRenderer = function (canvasId) {
  if (window.planetRenderers[canvasId]) {
    delete window.planetRenderers[canvasId];
  }
};
