classdef AlgorithmImplement < AlgorithmInterface
    %ALGORITHMIMPLEMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %继承题目接口
        %problemInterface;
    end
    
    %obj 特征
    properties
       %缓存数据
       cacheData;
       %迭代滤波残差
       dataZf;
       
       %试次开始点
       trialStartPoint;
       
       %计算所用数据长度
       sampleCount;
       %偏移数据长度
       offsetLength;
       %求解算法
       method;
        
       %预处理滤波器
       preprocessFilter;
       %选择导联序号
       selectChannel;
       %试次启始事件定义
       testTrialStartEvent;
        %训练模型
        model;
        %当前人员ID
        currentPersonId;
    end
    
    %初始化方程
    methods
        function initial(obj)
           %定义采样率，题目文件中给出
            srate = 250;
            
            %选择导联编号，具体导联编号题目文件中给出（需要编辑）
            obj.selectChannel = [26 29 30];          
            
            %试次启始事件定义，题目说明中给出
            obj.testTrialStartEvent = 1;

            %计算时间
            calTime = 2;     
            %设置初始实验对象为0
            obj.currentPersonId = 0;
            %计算偏移时间（s）
            offsetTime = 0;
            %数据偏移长度
            obj.offsetLength = floor(offsetTime * srate);
            %
            obj.sampleCount = calTime * srate;
            %
            obj.preprocessFilter = obj.getPreFilter(srate);             
            
            %初始化算法（使用PSD 算法）（需要编辑）
            obj.method = PSDClass();
            
        end
        
        
        
        %运转方程逻辑
        
        %1，设置停止标签与计算模式标签为否
        %2，如未到达停止标签处：
        %          》 索要数据
        %          》 如未到计算标签处：
        %                       - 计算标签=事件检测
        %          》如到计算标签处：
        %                       -进行计算（两个输出：CalFlag 和 resultType）
        %                       -如果监测到resultType：
        %                                   +汇报结果
        %          》设置停止标签为是 
        
        function run(obj)

            %是否停止标签（设为否）
            endFlag = false;
            
           %是否进入计算模式标签（设为否）
            calFlag = false;
            
            %当停止标签为否时
            while(~endFlag)
                %getdata: 提取当前模型的可调整的系数为一个array
                dataModel = obj.problemInterface.getData();
                
                %非计算模式则进行事件检测
                if(~calFlag)
                    
                    calFlag = obj.idleProcess(dataModel);
                    
                else
                    %计算模式，则进行处理
                    %两个输出： CalFlag 和 resultType
                    [calFlag,resultType] = obj.calculateProcess(dataModel);
                   
                    if(~isempty(resultType))
                        %如果有结果，则进行报告
                        reportModel = ReportModel();
                        reportModel.resultType = resultType;

                        obj.problemInterface.report(reportModel);
                        
                        %同时清空缓存
                        obj.clearCach();
                    end
                    
                end

                endFlag = dataModel.finishedFlag;
  
            end

        end
        
    end
    
    %当地函数
    methods(Access = private)
        function [calFlag] = idleProcess(obj,dataModel) 
            data = dataModel.data;
            % https://ww2.mathworks.cn/company/newsletters/articles/matrix-indexing-in-matlab.html
            % （:,:）先行再列: 全部行全部列
            eventData = data(end,:); % 最后一行的全部列
            % eventData == obj.testTrialStartEvent: returns an array 
            % if ture return 1
            % 寻找至多前一个在eventData == obj.testTrialStartEvent 当中
            eventPosition = find(eventData == obj.testTrialStartEvent,1);
            %eegData: 第一行到倒数第二行，全部列
            %通道采集的数据样本
            eegData = data(1:end-1,:);
            
            %%ISEMPTY True for empty array.
            %   ISEMPTY(X) returns 1 if X is an empty array and 0 otherwise. An
            %   empty array has no elements, that is prod(size(X))==0.
            %   如果到了testTrialStartEvent
            if(~isempty(eventPosition))
                calFlag = true;
                obj.trialStartPoint = eventPosition(1);
                % 所有行，从trialStartPoint开始到结束列
                % 将测量数据移动至内存空间数据
                obj.cacheData = eegData(:,obj.trialStartPoint:end);
            % 如果没有到testTrialStartEvent
            else
                calFlag = false;
                obj.trialStartPoint = []; %空集
                obj.clearCach();
            end

        end
        
        
        function [calFlag,resultType] = calculateProcess(obj,dataModel)
           
            data = dataModel.data;%(L+1)*N维矩阵
            %根据被试加载相应的训练模型
            personID = dataModel.personID;
            if(obj.currentPersonId~=personID)
                obj.currentPersonId = obj.currentPersonId + 1;
                %num2str convert number to string
                % loading the next person's model
                obj.model = load(['modelforPerson' num2str(obj.currentPersonId) '.mat']); 
            end
            %重新提取数据（和idleProcess 一样）
            eventData = data(end,:);
            eventPosition = find(eventData == obj.testTrialStartEvent,1);
            eegData = data(1:end-1,:);
            
            %如果event为空，表示依然在当前试次中，根据数据长度判断是否计算
            if(isempty(eventPosition))
                
%   M = SIZE(X,DIM) returns the lengths of the specified dimensions in a 
%   row vector. DIM can be a scalar or vector of dimensions. For example, 
%   SIZE(X,1) returns the number of rows of X and SIZE(X,[1 2]) returns a 
%   row vector containing the number of rows and columns.
                %cacheData 中装的是之前测量的数据
                cacheDataLength = size(obj.cacheData,2); %number of colomns
                
                %如果接收数据长度达到要求，则进行计算
                                            %sampleCount计算所用数据长度
                if(size(eegData,2)> obj.sampleCount - cacheDataLength)
                    %嫁接array: 2, obj.cacheData,
                    %eegData的第一列到（obj.sampleCount-cacheDataLength）列
                    %CAT(2,A,B) is the same as [A,B] 行数相同.
                    obj.cacheData = cat(2,obj.cacheData,eegData(:,1:obj.sampleCount - cacheDataLength));
                    %　cacheData里面的所有行，offsetlength+1 到end 列
                    usedData = double(obj.cacheData(:,obj.offsetLength+1:end));
                    %滤波处理
                    usedData = obj.preprocess(usedData);
                    %开始计算
                    %in PCDClass
                    resultType = obj.method.recognize(usedData,obj.model.trainModelPara,...
                        obj.model.srate,obj.model.sampleTime,obj.model.totalFlt,obj.model.psdFlt);  
                    %in CSP
                    
                    %停止计算模式
                    calFlag = false;
                %接收数据不到标准
                else
                    %反之继续采集数据
                    obj.cacheData = cat(2,obj.cacheData,eegData);  
                    resultType = [];
                    calFlag = true;
                end

            else
                %event非空，表示下一试次已开始，需要强制结束计算
                nextTrialStartPoint = eventPosition(1);
                cacheDataLength = size(obj.cacheData,2);
                usedLength = min([nextTrialStartPoint,obj.sampleCount - cacheDataLength]);
                
                obj.cacheData = cat(2,obj.cacheData,data(1:end-1,1:usedLength));
                usedData = double(obj.cacheData(:,obj.offsetLength+1:end));
                %滤波处理
                usedData = obj.preprocess(usedData);
                %开始计算
                %使用功率谱（PSD）计算
                resultType = obj.method.recognize(usedData,obj.model.trainModelPara,...
                    obj.model.srate,obj.model.sampleTime,obj.model.totalFlt,obj.model.psdFlt); 
               %使用CSP计算
                %开始新试次的计算模式
                calFlag = true;
            end
        
        end
        
    end
    
    %滤波器
    methods(Access = private)      
        function preprocessFilter = getPreFilter(~,srate)
            Fo = 50;
            Q = 35;
            BW = (Fo/(srate/2))/Q;
            [preprocessFilter.B,preprocessFilter.A] = iircomb(srate/Fo,BW,'notch');    
        end
        function clearCach(obj)
            obj.cacheData = [];
            obj.dataZf = [];     
        end
        
        %数据预处理
        function data = preprocess(obj,data)
            %选择通道
            data = data(obj.selectChannel,:);
    %   Y = FILTFILT(B, A, X) filters the data in vector X with the filter
    %   described by vectors A and B to create the filtered data Y.  The filter
    %   is described by the difference equation:
    %
    %     a(1)*y(n) = b(1)*x(n) + b(2)*x(n-1) + ... + b(nb+1)*x(n-nb)
    %                           - a(2)*y(n-1) - ... - a(na+1)*y(n-na)
    %
    %   The length of the input X must be more than three times the filter
    %   order, defined as max(length(B)-1,length(A)-1).
            %滤波（看gerPreFilter）
            data = filtfilt(obj.preprocessFilter.B ,obj.preprocessFilter.A ,data.');
            %transpose
            data = data.';

        end
    end
    
end

