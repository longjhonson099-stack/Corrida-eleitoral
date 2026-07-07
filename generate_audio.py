import wave
import struct
import math
import random
import os

SAMPLE_RATE = 44100

def generate_tone(filename, duration, start_freq, end_freq, wave_type='square', vol=0.5):
    num_samples = int(duration * SAMPLE_RATE)
    with wave.open(filename, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        
        for i in range(num_samples):
            t = i / SAMPLE_RATE
            # Linear frequency sweep
            freq = start_freq + (end_freq - start_freq) * (i / num_samples)
            
            val = 0
            if wave_type == 'square':
                val = 1.0 if math.sin(2 * math.pi * freq * t) > 0 else -1.0
            elif wave_type == 'noise':
                val = random.uniform(-1, 1)
                
            # Envelope (fade out)
            env = 1.0 - (i / num_samples)
            
            sample = int(val * env * vol * 32767)
            # Clip
            sample = max(-32768, min(32767, sample))
            f.writeframesraw(struct.pack('<h', sample))

os.makedirs('assets/audio', exist_ok=True)

# Jump: Pitch up
generate_tone('assets/audio/jump.wav', 0.2, 300, 600, 'square', 0.3)
# Shoot: Pitch down fast
generate_tone('assets/audio/shoot.wav', 0.15, 800, 200, 'square', 0.4)
# Explosion: Noise
generate_tone('assets/audio/explosion.wav', 0.5, 100, 100, 'noise', 0.6)
# Click: High short pip
generate_tone('assets/audio/click.wav', 0.05, 1200, 1200, 'square', 0.2)

print("Audio files generated.")
