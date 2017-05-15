%% rolling calculation per week
RollNum=52;         %%滚动次数
RollStart=(1:24*3:8737)';       %%滚动周期起始时间
%% full period input data
load input_data.mat
%%------------------------ initialization ---------------------------------
%%------------ system data
in.A=A;                      %% number of areas
in.T=0;                      %% time horizons
in.TD=TD;                    %% number of days
%%------------- area data
in.Nunit = Nunit;            %% number of units
in.Ntie  = Ntie;             %% number of tie lines
in.Pmax=Pmax;                %% unit maximum output
in.Pmin=Pmin;                %% unit minimum output
in.Rampup=Rampup;            %% unit ramping up rates
in.Rampdown=Rampdown;        %% unit ramping down rates
in.Minup=Minup;              %% unit minimun up time
in.Mindown=Mindown;          %% unit minimum dowm time
in.Onoff_t0=cell(1,A);       %% initial status at t=0
in.Pthermal_t0=cell(1,A);    %% initial output at t=0
in.On_t0=cell(1,A);          %% length of time unit g has to be on at the beginning
in.Off_t0=cell(1,A);         %% length of time unit g has to be off at the beginning
in.Demand=zeros(T,A);        %% demand
in.Windmax= zeros(T,A);      %% theory output of wind power
in.PVmax  = zeros(T,A);      %% theory output of PV
in.Tieline=Tieline;          %% tie lines
in.Ftie0=cell(1,A);          %% fixed power flow
in.Etie =cell(1,A);          %% exchage energy each day
in.TDstart=ones(1,TD+1);
%%-------------- results
Pwind_F=zeros(T,A);    %% output of wind power 
Ppv_F  =zeros(T,A);      %% output of PV 
Pthermal_F=cell(1,A);          %% output of thermal unit
onoff_F=cell(1,A);           %% on_off status;
startup_F=cell(1,A);              %% start up indicator
shutdown_F=cell(1,A);            %% shut down indicator
Ftie_F=cell(1,A);

%% roll up
tic;
for roll=1:RollNum
    %%input the rth rolling period data
    for a=1:A
        in.T=RollStart(roll+1)-RollStart(roll);
        if roll==1
            in.Onoff_t0{a}=Onoff_t0{a};       
            in.Pthermal_t0{a}=Pthermal_t0{a};   
            in.On_t0{a}=On_t0{a};         
            in.Off_t0{a}=Off_t0{a};       
        else
            in.Onoff_t0{a}=out.onoff{a}(in.T,:);      
            in.Pthermal_t0{a}=out.Pthermal{a}(in.T);    
            [in.On_t0{a},in.Off_t0{a}] = getOnoff_t0(out.onoff{a},in.Minup{a},in.Mindown{a});       
        end
    end
    in.Demand  = Demand(RollStart(roll):RollStart(roll+1)-1,:);        
    in.Windmax = Windmax(RollStart(roll):RollStart(roll+1)-1,:); 
    in.PVmax   = PVmax(RollStart(roll):RollStart(roll+1)-1,:);    
    %%solution
    out=across_region_accommodation(in);
    %%results
    Pwind_F(RollStart(roll):RollStart(roll+1)-1,:)= out.Pwind;    %% output of wind power 
    Ppv_F(RollStart(roll):RollStart(roll+1)-1,:)  = out.Ppv;      %% output of PV 
    for a=1:A
        Pthermal_F{a}(RollStart(roll):RollStart(roll+1)-1,:) = out.Pthermal{a};
        onoff_F{a}(RollStart(roll):RollStart(roll+1)-1,:)    = out.onoff{a};
        startup_F{a}(RollStart(roll):RollStart(roll+1)-1,:)  = out.startup{a};
        shutdown_F{a}(RollStart(roll):RollStart(roll+1)-1,:) = out.shutdown{a};
    end
    for a=1:A
        Ftie_F{a}(RollStart(roll):RollStart(roll+1)-1,:)      = out.Ftie{a};
    end
    roll
    toc;
end
%% display results
for a=1:A
    %%------------------------ thermal unit -------------------------------
    figure;
    stairs(Pthermal_F{a});
    title(['thermal unit output in area' num2str(a)]);
    %%------------------------------- wind ------------------------------------
    figure;
    hold on;
    stairs(Windmax(:,a));
    stairs(Pwind_F(:,a));
    title(['wind power in area' num2str(a)]);
    hold off;
    %%-------------------------------- PV -------------------------------------
    figure;
    hold on;
    stairs(PVmax(:,a));
    stairs(Ppv_F(:,a));
    title(['PV generation in area' num2str(a)]);
    hold off;  
end
%%------------------------------- tie lines -------------------------------
for a=1:A
    for b=a+1:A
        for la=1:Ntie(a)
            for lb=1:Ntie(b)
                if (Tieline{a}(la,1)==b)&&(Tieline{b}(lb,1)==a)
                    figure;
                    hold on;
                    stairs(Ftie_F{a}(:,la));
                    stairs(Ftie_F{b}(:,lb));
                    legend(['Tie ' num2str(a) '-' num2str(b)],['Tie ' num2str(b) '-' num2str(a)]); 
                    title('tie line power flow');
                    hold off;
                end
            end
        end
    end
end