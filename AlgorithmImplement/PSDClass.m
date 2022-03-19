classdef PSDClass < handle
    %PSDCLASS Summary of this class goes here
    %   Detailed explanation goes here
    properties
        
    end
    
    methods       
        function resultType = recognize(obj,testData,trainModelPara,srate,sampleTime,totalFlt,psdFlt)
            %滤波
            [preProccessedTestData] = preProccess(srate,sampleTime,testData,totalFlt);
            resultType = testFeaturePSD(preProccessedTestData,trainModelPara,srate,psdFlt);
        end
    end
    
end