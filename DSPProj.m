clc;
clear all;
close all;

% Load the original audio
[originalAudio, fs] = audioread('./speech.wav');

% Load the noise audio
[noiseAudio, ~] = audioread('./noice.wav');

% To ensure both audio files have the same length
minLength = min(length(originalAudio), length(noiseAudio));
originalAudio = originalAudio(1:minLength);
noiseAudio = noiseAudio(1:minLength);

% mix the original audio and noise

mixingRatio = 0.5; % Adjust the mixing ratio as needed
mixedAudio = mixingRatio * originalAudio + (1 - mixingRatio) * noiseAudio;

% Plotting the time domain representation of the mixed signal

t = (0:length(mixedAudio)-1) / fs;
figure;
subplot(2,2,1);
plot(t, mixedAudio);
title('Mixed Audio (Original + Noise)');
xlabel('Time (s)');
ylabel('Amplitude');

% Saving the mixed audio to a new file
audiowrite('mixed_audio.wav', mixedAudio, fs);

% Applying advanced noise removal using Ephraim-Malah algorithm
alpha = 0.99; % Smoothing factor
beta = 0.002; % Bias factor

% Initialize noise estimate with the first element of originalAudio
noiseEstimate = abs(originalAudio(1));
denoisedAudio = zeros(size(originalAudio));

for i = 2:length(originalAudio)
    % Updating noise estimate using Ephraim-Malah algorithm
    noiseEstimate = alpha * max(noiseEstimate, abs(originalAudio(i) - noiseEstimate));

    % Performing spectral subtraction
    denoisedAudio(i) = max(0, abs(originalAudio(i)) - beta * noiseEstimate) * sign(originalAudio(i));
end


% Plotting the time domain representation of the denoised signal
subplot(2,2,2);
plot(t, denoisedAudio);
title('Denoised Audio');
xlabel('Time (s)');
ylabel('Amplitude');

% Saving the denoised audio to a new file
audiowrite('denoised_audio.wav', denoisedAudio, fs);

% Applying reverb effect
numChannels = 4;
delayLengths = [0.0297, 0.0371, 0.0419, 0.0437];
feedbackMatrix = 0.9 * eye(numChannels);  % Increase the feedback values

% Calculating the maximum delay length in samples
maxDelaySamples = round(max(delayLengths) * fs);

% Initializing delay lines
delayLines = zeros(maxDelaySamples, numChannels);

reverbAudio = zeros(size(denoisedAudio));
for i = 1:length(denoisedAudio)
    for j = 1:numChannels
        delayLines(:, j) = [denoisedAudio(i); delayLines(1:end-1, j)];
        reverbAudio(i) = reverbAudio(i) + delayLines(end, j);
    end
    delayLines = delayLines * feedbackMatrix;
end


% Normalize the reverb audio
reverbAudio = reverbAudio / max(abs(reverbAudio));

% Plot the time domain representation of the reverb signal
subplot(2,2,3);
plot(t, reverbAudio);
title('Reverb Audio');
xlabel('Time (s)');
ylabel('Amplitude');

audiowrite('final_audio.wav', reverbAudio, fs);

% Plot the frequency domain representation of the mixed signal
nfft = 2^nextpow2(length(mixedAudio)); % Choose a power of 2 for the FFT
frequencies_mixed = (0:nfft-1) * fs / nfft;
mixedAudio_fft = fft(mixedAudio, nfft);

subplot(2,2,4);
plot(frequencies_mixed, 2/nfft * abs(mixedAudio_fft(1:nfft)));
title('Frequency Domain Representation (Mixed Audio)');
xlabel('Frequency (Hz)');
ylabel('Amplitude');
xlim([0, fs/2]);