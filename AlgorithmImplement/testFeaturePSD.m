function resultType = testFeaturePSD(testData,trainModelPara,srate,psdFlt)
% 功率谱参数
nfft=srate;
window=hamming(size(testData,1)); % # of rows in testData (all channels)
noverlap=floor(length(window)/2); 
range='onesided';
% 计算功率谱
avgspectrum1=[];
avgspectrum2=[];

%   [Pxx,F] = PWELCH(X,WINDOW,NOVERLAP,NFFT,Fs) returns a PSD computed as
%   a function of physical frequency.  Fs is the sampling frequency
%   specified in hertz.  If Fs is empty, it defaults to 1 Hz.
%
%   F is the vector of frequencies (in hertz) at which the PSD is
%   estimated.  For real signals, F spans the interval [0,Fs/2] when NFFT
%   is even and [0,Fs/2) when NFFT is odd.  For complex signals, F always
%   spans the interval [0,Fs).
[Pxx,F]=pwelch(testData(:,2),window,noverlap,nfft,srate,range);  %C3
avgspectrum1=cat(2, avgspectrum1, Pxx);

[Pxx,F]=pwelch(testData(:,3),window,noverlap,nfft,srate,range);  %C4
avgspectrum2=cat(2, avgspectrum2, Pxx);

test_PSD_feature = avgspectrum1-avgspectrum2;

% 功率谱特征
test_PSD_feature = test_PSD_feature(floor(psdFlt(1)*(nfft/srate)):floor(psdFlt(2)*(nfft/srate)),:);
test_PSD_feature = test_PSD_feature';

% 分类
resultType = predict(trainModelPara,test_PSD_feature);
end