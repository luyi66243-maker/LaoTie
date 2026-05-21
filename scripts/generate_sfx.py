import wave, struct, math, os

output_dir = "/Users/yi/Qoder/LaoTie/LaoTie/Resources/Audio"

def generate_tone(filename, frequency, duration, volume=0.5, fade=True):
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    with wave.open(os.path.join(output_dir, filename), 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        for i in range(num_samples):
            t = i / sample_rate
            amp = volume
            if fade and i > num_samples * 0.7:
                amp *= (num_samples - i) / (num_samples * 0.3)
            value = int(amp * 32767 * math.sin(2 * math.pi * frequency * t))
            f.writeframes(struct.pack('<h', max(-32767, min(32767, value))))

def generate_multi_tone(filename, tones, duration, volume=0.3):
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    with wave.open(os.path.join(output_dir, filename), 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(sample_rate)
        for i in range(num_samples):
            t = i / sample_rate
            amp = volume
            if i > num_samples * 0.6:
                amp *= (num_samples - i) / (num_samples * 0.4)
            value = sum(math.sin(2 * math.pi * freq * t) for freq in tones)
            value = int(amp * 32767 * value / len(tones))
            f.writeframes(struct.pack('<h', max(-32767, min(32767, value))))

# 1. button_tap
generate_tone("button_tap.wav", 1200, 0.05, 0.3)

# 2. correct
sample_rate = 44100
duration = 0.3
num_samples = int(sample_rate * duration)
with wave.open(os.path.join(output_dir, "correct.wav"), 'w') as f:
    f.setnchannels(1)
    f.setsampwidth(2)
    f.setframerate(sample_rate)
    for i in range(num_samples):
        t = i / sample_rate
        freq = 523 if t < 0.15 else 784
        amp = 0.4
        if i > num_samples * 0.7:
            amp *= (num_samples - i) / (num_samples * 0.3)
        value = int(amp * 32767 * math.sin(2 * math.pi * freq * t))
        f.writeframes(struct.pack('<h', max(-32767, min(32767, value))))

# 3. wrong
with wave.open(os.path.join(output_dir, "wrong.wav"), 'w') as f:
    f.setnchannels(1)
    f.setsampwidth(2)
    f.setframerate(sample_rate)
    duration_w = 0.4
    num_samples_w = int(sample_rate * duration_w)
    for i in range(num_samples_w):
        t = i / sample_rate
        freq = 300 - (t * 200)
        amp = 0.35
        if i > num_samples_w * 0.6:
            amp *= (num_samples_w - i) / (num_samples_w * 0.4)
        value = int(amp * 32767 * math.sin(2 * math.pi * freq * t))
        f.writeframes(struct.pack('<h', max(-32767, min(32767, value))))

# 4. achievement
generate_multi_tone("achievement.wav", [523, 659, 784, 1047], 0.6, 0.3)

# 5. streak
generate_multi_tone("streak.wav", [392, 494, 587], 0.5, 0.3)

print("所有音效文件已生成!")
for name in ["button_tap.wav", "correct.wav", "wrong.wav", "achievement.wav", "streak.wav"]:
    path = os.path.join(output_dir, name)
    size = os.path.getsize(path)
    print(f"  {name}: {size} bytes")
