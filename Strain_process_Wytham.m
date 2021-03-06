%% Example strain data processing by tobydjackson@gmail.com

%This code runs the filtering and smoothing on the raw strain data for
%trees 18-21. Some steps are repeated for testing purposes.
%The calibration information for T18_21 are:
attachement_angles=[220.00000	117.00000	200.00000	310.00000	288.00000	190.00000	190.00000	278.00000];
calibration= [-12.04156	-13.17500	-14.46494	-15.67004	-12.65817	-18.40704	-12.59363	-10.38261];
arm_lengths=  [130.00000	130.00000	130.00000	130.00000	130.00000	130.00000	130.00000	130.0000 ];
load('C:\Users\Toby\Dropbox\Tobys_Stuff\MATLAB\Strain_data_test\Wytham\T18_21_AllData.mat')
sample=6e6:6.1e6;
%%
sample=20000:length(T18_21_AllData);
plot(datetime(T18_21_AllData(sample,1), 'ConvertFrom', 'datenum'),T18_21_AllData(sample,2));

% =======================================
%% 1. Filter and convert from mV data to strain 
% =======================================

data=T18_21_AllData(sample,:);  % Subselect to handle less data (optional)

for col=2:9
    col_data=data(:,col);
    %Filtering for outliers and NaN's
    col_data(find(col_data>=100))=0; %positive outliers
    col_data(find(col_data<=-100))=0; %negative outliers
    col_data(find(isnan(col_data==1)))=0; %NaN's
    %divide by arm length and voltage to extension calibration coefficients
    col_data=col_data/(arm_lengths(col-1)*calibration(col-1));
    if col==2
        data_out=col_data;
    else
        data_out=cat(2,data_out,col_data);% cat together the infor from all the pairs
    end
end % end loop over cols
T_cal=cat(2,data(:,1),data_out);
%clearvars data data_out T18_21_AllData

% Re-project Northward and Eastward 
for col=2:2:8
    unsmoothed_NE(:,col)=  T_cal(:,col).*cosd(attachement_angles(col-1))+T_cal(:,col+1).*sind(attachement_angles(col));
    unsmoothed_NE(:,col+1)=T_cal(:,col).*sind(attachement_angles(col-1))+T_cal(:,col+1).*cosd(attachement_angles(col));
end
unsmoothed_NE(:,1)=T_cal(:,1); % this version of the data was uploaded to EIDC

% ======================
%% 2. Subtract offsets
% ====================

%Test a few different runing mode window lengths
for col=2:9
    [smoothed1000_NE(:,col-1)   modes1000(:,col-1)]=  Running_mode(unsmoothed_NE(:,col),1000);
    [smoothed5000_NE(:,col-1)   modes5000(:,col-1)]=  Running_mode(unsmoothed_NE(:,col),5000);
    [smoothed15000_NE(:,col-1) modes15000(:,col-1)]=Running_mode(unsmoothed_NE(:,col),15000);
    [smoothed45000_NE(:,col-1) modes45000(:,col-1)]=Running_mode(unsmoothed_NE(:,col),45000);
end

%% Plot out the different running modes to se how much variation they are actually subtracting
sample=6e6:6.1e6;
for col=1:8;
    subplot(4,1,1)
    plot(datetime(unsmoothed_NE(sample,1), 'ConvertFrom', 'datenum'),unsmoothed_NE(sample,col+1));
    title('Unsmoothed'); set(gca,'xticklabel',{[]}) ;
    subplot(4,1,2)
    plot(datetime(unsmoothed_NE(sample,1), 'ConvertFrom', 'datenum'),smoothed1000_NE(sample,col));
    title('1000 point (4 minute) running mode'); set(gca,'xticklabel',{[]}) ;
    subplot(4,1,3)
    plot(datetime(unsmoothed_NE(sample,1), 'ConvertFrom', 'datenum'),smoothed1000_NE(sample,col));
    title('5000 point (21 minute) running mode'); set(gca,'xticklabel',{[]}) ;
    subplot(4,1,4)
    plot(datetime(unsmoothed_NE(sample,1), 'ConvertFrom', 'datenum'),smoothed1000_NE(sample,col));
    title('15000 point (62 minute) running mode'); 
    pause
end


%% Plot out the different running modes to se how much variation they are actually subtracting
sample=6000000:6890000;
col=8;
plot(datetime(unsmoothed_NE(sample,1), 'ConvertFrom', 'datenum'),unsmoothed_NE(sample,col+1));
hold on
plot(datetime(unsmoothed_NE(sample,1), 'ConvertFrom', 'datenum'),modes1000(sample,col));
plot(datetime(unsmoothed_NE(sample,1), 'ConvertFrom', 'datenum'),modes5000(sample,col));
plot(datetime(unsmoothed_NE(sample,1), 'ConvertFrom', 'datenum'),modes15000(sample,col));
plot(datetime(unsmoothed_NE(sample,1), 'ConvertFrom', 'datenum'),modes45000(sample,col));
h=legend('Strain data','4 minute mode','21 minute mode','62 minute mode','187 minute mode');
legend boxoff
title('Running mode window lengths')
ylabel('strain')
set([gca h], 'FontName', 'Helvetica','FontSize', 12)

%% Test a running mean vs mode vs mean then mode
col=2
[mode_NE temp_mode] =  Running_mode(unsmoothed_NE(:,col),5000);
temp_mean=running_mean(unsmoothed_NE(:,col),5000);
mean_NE=  unsmoothed_NE(:,col)-temp_mean;

sample=6000000:6890000;
plot(datetime(unsmoothed_NE(sample,1), 'ConvertFrom', 'datenum'),unsmoothed_NE(sample,col));
hold on
plot(datetime(unsmoothed_NE(sample,1), 'ConvertFrom', 'datenum'),temp_mode(sample));
plot(datetime(unsmoothed_NE(sample,1), 'ConvertFrom', 'datenum'),temp_mean(sample));
h=legend('Strain data','Running mode','Running mean');
legend boxoff
title('Subtract offsets')
ylabel('strain')
set([gca h], 'FontName', 'Helvetica','FontSize', 12)
%%
subplot(1,2,1)
histogram(mean_NE(sample));
hold on
plot([0 0],[0 5e4],'r--','LineWidth',2.5)
xlim([-1e-4 2e-4])
title('Running mean')
subplot(1,2,2)
histogram(mode_NE(sample));
hold on
plot([0 0],[0 5e4],'r--','LineWidth',2.5)
xlim([-1e-4 2e-4])
title('Running mode')


%% 2. Convert T1_cal strain data to max strain
data=cat(2,unsmoothed_NE(:,1),smoothed1000_NE,smoothed5000_NE,smoothed15000_NE,smoothed45000_NE);
%clearvars col_data unsmoothed_NE smoothed1000_NE smoothed5000_NE smoothed15000_NE smoothed45000_NE
%clearvars modes1000 modes5000 modes15000 modes45000
T_MaxStrain(:,1)=data(:,1);  
c=1;
for pair=2:2:32
    c=c+1;
    T_MaxStrain(:,c)=sqrt(data(:,pair).^2+data(:,pair+1).^2); 
end

%% Plot two channels and max strain
sample=6008000:6010000;
subplot(3,1,1)
plot(datetime(data(sample,1), 'ConvertFrom', 'datenum'),data(sample,8));
title('Strain on North facing side of trunk')
ylabel('strain')

subplot(3,1,2)
plot(datetime(data(sample,1), 'ConvertFrom', 'datenum'),data(sample,9));
title('Strain on East facing side of trunk')
ylabel('strain')

subplot(3,1,3)
plot(datetime(T_MaxStrain(sample,1), 'ConvertFrom', 'datenum'),T_MaxStrain(sample,5));
title('Max Strain')
ylabel('strain')



%==================
%% 3. Select maxima
%==================

%Loop over hourly wind data and select max strain in each hour - test robust max and window effect of window length
%  WARNING: This section can be slow if you have lots of data input + robust_max
load('hourly_wind_data.mat') %This data isn't mine - it was collected by the Environmental Change Network
 % ECN hourly data, column 1= time, 2= mean WS, 3= max WS
data_in=T_MaxStrain;   

no_cols=size(data_in,2);  
data_out=NaN(5951,size(data_in,2));
data_out_robust=NaN(5951,size(data_in,2));
%Now we loop over the hours of ECN data and find the max of tree strain data within that hour
for hour= [2293:2366   2775:2940 3690:3900 5150:5370]  % I have roughly selected the hours which contain data for T18_21, just to speed things up.
    %
    low=hourly_wind_data(hour-1,1); high=hourly_wind_data(hour,1); %Select the datenums at the start and end of the hour
    rows=find(data_in(:,1)>=low & data_in(:,1)<high); %Find strain data within that hour
    if length(rows)<14000 continue %If there is too little strain data skip it
    end
    if hourly_wind_data(hour,3)==0 continue  %If there was no wind (or more often errors give 0) skip it
    end
    [hour ]
    data_out(hour,:)=max(data_in(rows,:)); %simple max data out - this should be good enough.
    data_out_robust(hour,:)=robust_max(data_in(rows,:)); %robbust max data out - tjust for testing purposes
end

T_hourly=cat(2,data_out(:,1),hourly_wind_data(:,2:3),data_out(:,2:end));
T_hourly_robust=cat(2,data_out(:,1),hourly_wind_data(:,2:3),data_out_robust(:,2:end));
%These matrices have col1=time, col2:3=wind speeds, col4:end=strain maxima
%% Plot them out
for col=4:size(T_hourly,2)
    scatter(T_hourly(:,2),T_hourly(:,col))
    hold on
    scatter(T_hourly_robust(:,2),T_hourly_robust(:,col))
    pause
    close all
end



%===========================================
%% 4. Extrapolation up to Critical Wind Speed (CWS)
%===========================================

%% 4. Calculate critical wind speed for each window length
breaking_strain=5e-3; %this should be taken for the literature or tested for each tree
for tree=1:16
    tree
    col=tree+3;
    Winter = cat(2,T_hourly(1:2999,3),T_hourly(1:2999,col)) ;
    Winter(Winter(:,2)==-inf,2)=NaN;     %Checks for infinities
    for col = 1:2      %Removes the NaN
        Winter = Winter(isnan(Winter(:,col))== 0,:);
    end
    strain=Winter(:,2);
    wind=Winter(:,1);
    ft = fittype( 'a*x', 'independent', 'x', 'dependent', 'y' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    opts.Robust = 'LAR';
    [fit_square_data, gof_square_data] = fit(wind.^2,strain,ft,opts);
    save_norms(tree)=fit_square_data.a;
    CWS_square(tree) = [(breaking_strain/(save_norms(tree))).^(1/2)]; 
end
times=strvcat('4 .16 mins' , '20.8 mins' ,'1.02 hours', '3.08 hours');
window_sensitivity=table([ 1000 5000 15000 45000]',  times,CWS_square(:,[1 5 9 13])' ,CWS_square(:,[2 6 10 14])', CWS_square(:,[3 7 11 15])', CWS_square(:,[4 8 12 16])' ,'VariableNames',{'points', 'times','Tree18','Tree19','Tree20','Tree21'})


%% 4. Calculate critical wind speed using both square law fitting and log-log fitting
breaking_strain=5e-3; %this is taken from the literature and up for debate.
PLOT=1;
for tree=1:4
    tree
    col=tree+3;
    Winter = cat(2,T_hourly(1:2999,3),T_hourly(1:2999,col)) ;
    Winter(Winter(:,2)==-inf,2)=NaN;     %Checks for infinities
    for col = 1:2      %Removes the NaN
        Winter = Winter(isnan(Winter(:,col))== 0,:);
    end
    strain=Winter(:,2);
    wind=Winter(:,1);
    
    ft = fittype( 'a*x', 'independent', 'x', 'dependent', 'y' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    opts.Robust = 'LAR';
    [fit_square_data, gof_square_data] = fit(wind.^2,strain,ft,opts);
    save_norms(tree)=fit_square_data.a;
    CWS_square(tree) = [(breaking_strain/(save_norms(tree))).^(1/2)]; 
    
     p=gmregress(log(wind),log(strain),0.05);
    data_fit_line= wind.^p(2).*exp(p(1));
    save_norms_loglog(tree)=[p(1)];
    save_exponents_loglog(tree)=(p(2));
    CWS_loglog(tree) = [(breaking_strain/(exp(save_norms_loglog(tree)))).^(1/ save_exponents_loglog(tree))];     
    fit_loglog_data=exp(p(1)).*(1:0.1:25).^p(2);
        
    if PLOT==1
    subplot(1,2,1) % SQUARE LAW FIT PLOT
        color=jet(10);
        h1 = plot( wind.^2, strain,'+','Color',color(2,:));
        hold on
        h_data_fit=line(linspace(0,25,100).^2,(save_norms(tree))*(linspace(0,25,100).^2),'Color',color(5,:));
        hbreak=plot(linspace(0,CWS_square(tree).^2,1000)',breaking_strain*ones(1000,1),'r--');
        ylim([1e-5 breaking_strain+0.002])
        xlabel('Max wind speed')
        ylabel('Max strain')  
        set(gca, 'FontName', 'Helvetica','FontSize', 12)
    
        subplot(1,2,2) % LOGLOG Semi-Major-Axis FIT
        h2 = loglog( wind, strain,'.','Color',color(2,:));
        hold on
        h2_fitline=loglog(wind,data_fit_line,'Color',color(5,:),'LineWidth',1.5);
        hbreak=plot(linspace(0,100,1000)',breaking_strain*ones(1000,1),'r--');
        legend off
        grid off
        ylim([0 breaking_strain+0.002])
        xlim([1 CWS_loglog(tree)+20])
         xlabel('log(Max wind speed)')
        ylabel('log(Max strain)')  
        set(gca, 'FontName', 'Helvetica','FontSize', 12)
        pause
        close all
    end  
end

fit_type=strvcat('n == 2' , 'log SMA' );
CWSs=[CWS_square(:,[1:4]); CWS_loglog(:,[1:4])];
fitting_sensitivity=table( fit_type, CWSs(:,1), CWSs(:,2),  CWSs(:,3),   CWSs(:,4)   ,'VariableNames',{ 'Types','Tree18','Tree19','Tree20','Tree21'})



