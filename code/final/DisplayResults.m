% load data & display results
%% load data
in_full = load('input_data.mat', 'in');
in_full = in_full.in;
load results.mat;
close all
A=2;
Starth=24*1;
Endh=24*2;
%% display results
for a=1:A
    %%------------------------ thermal unit -------------------------------
    figure;
    stairs(out_full(a).Pthermal(Starth:Endh,:));
    title(['thermal unit output in area' num2str(a)]);
    %%------------------------------- wind ------------------------------------
    figure;
    hold on;
    stairs(in_full(a).Windmax(Starth:Endh));
    stairs(out_full(a).Pwind(Starth:Endh));
    title(['wind power in area' num2str(a)]);
    legend('maximum','actual');
    hold off;
    %%-------------------------------- PV -------------------------------------
    figure;
    hold on;
    stairs(in_full(a).PVmax(Starth:Endh));
    stairs(out_full(a).Ppv(Starth:Endh));
    title(['PV generation in area' num2str(a)]);
    legend('maximum','actual');
    hold off;  
end
%%------------------------------- tie lines -------------------------------
for a=1:A
    for b=a+1:A
        for la=1:in_full(a).Ntie
            for lb=1:in_full(b).Ntie
                if (in_full(a).Tieline(la,1)==b)&&(in_full(b).Tieline(lb,1)==a)
                    figure;
                    hold on;
                    stairs(out_full(a).Ftie(Starth:Endh,la));
                    stairs(out_full(b).Ftie(Starth:Endh,lb));
                    legend(['Tie ' num2str(a) '-' num2str(b)],['Tie ' num2str(b) '-' num2str(a)]); 
                    title('tie line power flow');
                    hold off;
                end
            end
        end
    end
end
%----------------------------- energy distribution ------------------------
for a=1:A
    figure;
    hold on;
%     area(Demand(1:Endh,a),'FaceColor','g','EdgeColor','g');
    area(sum(out_full(a).Pthermal(Starth:Endh,:),2)+out_full(a).Pwind(Starth:Endh)+out_full(a).Ppv(Starth:Endh)-sum(out_full(a).Ftie(Starth:Endh,:),2),'FaceColor','k','EdgeColor','k');
    area(sum(out_full(a).Pthermal(Starth:Endh,:),2)+out_full(a).Pwind(Starth:Endh)+out_full(a).Ppv(Starth:Endh),'FaceColor','r','EdgeColor','r');
    area(sum(out_full(a).Pthermal(Starth:Endh,:),2)+out_full(a).Pwind(Starth:Endh),'FaceColor','y','EdgeColor','y');
    area(sum(out_full(a).Pthermal(Starth:Endh,:),2),'FaceColor','b','EdgeColor','b');
    plot(out_full(a).Ppv(Starth:Endh));
    plot(out_full(a).Pwind(Starth:Endh));
    plot(in_full(a).Demand(Starth:Endh),'-*');
    plot(out_full(a).Ftie(Starth:Endh,:));
%     plot(in_full(a).Demand(Starth:Endh)+sum(out_full(a).Ftie(Starth:Endh,:),2));
    legend('Tieline','PV','Wind','Thermal','PV','Wind','Demand','Tieline');
    title(['energy distribution in area ' num2str(a)]);
    hold off;
end

%% statistic
%-------------------------------- 发电量 ----------------------------------
Egy_str={'demand';'tieline';'thermal';'wind';'PV';'new';'windmax';'PVmax';'newmax';'windspill';'PVspill';'newspill';'generation'};
Egy_tbl=zeros(13,A+1);
for a=1:A
    Egy_tbl(1,a) = sum(in_full(a).Demand(Starth:Endh));    %% demand
    Egy_tbl(2,a) = sum(sum(out_full(a).Ftie(Starth:Endh,:)));          %% tieline
    Egy_tbl(3,a) = sum(sum(out_full(a).Pthermal(Starth:Endh,:)));      %% thermal
    Egy_tbl(4,a) = sum(out_full(a).Pwind(Starth:Endh));                 %% wind
    Egy_tbl(5,a) = sum(out_full(a).Ppv(Starth:Endh));                   %% PV
    Egy_tbl(7,a) = sum(in_full(a).Windmax(Starth:Endh));   %% windmax
    Egy_tbl(8,a) = sum(in_full(a).PVmax(Starth:Endh));     %% PVmax
end
Egy_tbl(6,:)  = Egy_tbl(4,:) + Egy_tbl(5,:);                    %% RG
Egy_tbl(9,:)  = Egy_tbl(7,:) + Egy_tbl(8,:);                    %% RGmax
Egy_tbl(10,:) = Egy_tbl(7,:) - Egy_tbl(4,:);                    %% wind spill
Egy_tbl(11,:) = Egy_tbl(8,:) - Egy_tbl(5,:);                    %% PV spill
Egy_tbl(12,:) = Egy_tbl(10,:)+ Egy_tbl(11,:);                   %% RG spill
Egy_tbl(13,:) = Egy_tbl(3,:) + Egy_tbl(4,:) + Egy_tbl(5,:);     %% total generation
Egy_tbl(:,A+1)= sum(Egy_tbl(:,1:A),2);
EgyTable=array2table(Egy_tbl,'RowNames',Egy_str)
%-------------------------------- 比例 ------------------------------------
Pct_str={'thermal/demand';'wind/demand';'PV/demand';'new/demand';'windspill/windmax';'PVspill/PVmax';'newspill/newmax'};
Pct_tbl=zeros(7,A+1);
Pct_tbl(1,:) =  Egy_tbl(3,:)./ Egy_tbl(1,:);
Pct_tbl(2,:) =  Egy_tbl(4,:)./ Egy_tbl(1,:);
Pct_tbl(3,:) =  Egy_tbl(5,:)./ Egy_tbl(1,:);
Pct_tbl(4,:) =  Egy_tbl(6,:)./ Egy_tbl(1,:);
Pct_tbl(5,:) =  Egy_tbl(10,:)./ Egy_tbl(7,:);
Pct_tbl(6,:) =  Egy_tbl(11,:)./ Egy_tbl(8,:);
Pct_tbl(7,:) =  Egy_tbl(12,:)./ Egy_tbl(9,:);
PctTable=array2table(Pct_tbl,'RowNames',Pct_str)