classdef ProblemInterface < handle
    methods(Abstract)      
        %获取数据接口，返回DataModel类型变量
        %getdata: 提取当前模型的可调整的系数为一个array
        dataModel = getData(obj);        
        %结果报告接口，输入ReportModel类型变量
        report(obj,reportModel);       
    end
end

