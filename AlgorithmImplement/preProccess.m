function [bandPassData] = preProccess(Fs,windowLength,rawData,totalFlt)
%PREPROCCESS 预处理（通道选择、去基线漂移、带通滤波）
%   INPUT:  Fs            采样率
%           windowLength            单次采样时间
%           rawData       原始脑电数据
%           chanSelect    通道选择
%           totalFlt      总的滤波频段选择
%   OUTPUT: bandPassData  预处理后脑电数据
trialDataNum = Fs*windowLength;
cnt = rawData';
rawData1=double(cnt);
%% 去基线漂移
for i = 1:size(rawData1,1)/trialDataNum
    data1 = rawData1((i-1)*trialDataNum+1:i*trialDataNum,:);
    detrendData((i-1)*trialDataNum+1:i*trialDataNum,:) = detrend(data1);
end

%% 带通滤波
Wn1 = [totalFlt(1)*2 totalFlt(2)*2]/Fs;
[BB1,AA1] = butter(3,Wn1);  %6阶，4-40Hz带通
for i=1:size(detrendData,1)/trialDataNum
    data1 = detrendData((i-1)*trialDataNum+1:i*trialDataNum,:);
    bandPassData((i-1)*trialDataNum+1:i*trialDataNum,:) = filter(BB1,AA1,data1);
end

end