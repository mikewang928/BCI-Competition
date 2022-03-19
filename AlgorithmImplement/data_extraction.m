clear; close all; clc;

%%
S15_b1 = load("./mi_TrainData/S15/block1.mat").data;
label = S15_b1(65,:);
Y = label(376:1500:end);
Y(41) = [];
Y = Y';
X = zeros(40,59,1000);
for i = 1:40
    for j = 1:59
        X(i,j,:) = S15_b1(j,376+1500*(i-1):375+1000*i+500*(i-1));
    end
end
X = X(:,26,1:250);
X_2d = reshape(X,[40 1*250]);

%%
Model = fitcsvm(X_2d,Y,'OptimizeHyperparameters','auto',...
    'HyperparameterOptimizationOptions',...
    struct('MaxObjectiveEvaluations',60));

%%
y_output = predict(Model,X_2d);

sum(y_output == Y)/40


