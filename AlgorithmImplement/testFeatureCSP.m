function resultType = testFeatureCSP(testData,TrainModelPara,srate,psdFlt)
%CSP function
%Covanriance left
while()
    if (left)
        EEGCal = testData(1:end-1,:);
        CovL = (EEGCal*EEGCal')/trace(EEGCal*EEGCal');
        CovLT = CovLT+CovL;
        counterCovL++;
    else
        EEGCal = testData(1:end-1,:);
        CovR = (EEGCal*EEGCal')/trace(EEGCal*EEGCal');
        CovLR = CovLR+CovL;
        counterCovL++;
    end
end