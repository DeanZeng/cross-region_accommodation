% load data & display results
%% load data
% in_full = load('input_data.mat', 'in');
% in_full = in_full.in;
% load results_24X364.mat;
A=2;
Starth=1;
Endh=24*30;
%% display results
for a=1:A
    %%------------------------ thermal unit -------------------------------
    figure;
    stairs(Pthermal_F{a}(Starth:Endh,:));
    title(['thermal unit output in area' num2str(a)]);
    %%------------------------------- wind ------------------------------------
    figure;
    hold on;
    stairs(in_full.area(a).Windmax(Starth:Endh));
    stairs(Pwind_F(Starth:Endh,a));
    title(['wind power in area' num2str(a)]);
    legend('maximum','actual');
    hold off;
    %%-------------------------------- PV -------------------------------------
    figure;
    hold on;
    stairs(in_full.area(a).PVmax(Starth:Endh));
    stairs(Ppv_F(Starth:Endh,a));
    title(['PV generation in area' num2str(a)]);
    legend('maximum','actual');
    hold off;  
end
%%------------------------------- tie lines -------------------------------
for a=1:A
    for b=a+1:A
        for la=1:in_full.area(a).Ntie
            for lb=1:in_full.area(b).Ntie
                if (in_full.area(a).Tieline(la,1)==b)&&(in_full.area(b).Tieline(lb,1)==a)
                    figure;
                    hold on;
                    stairs(Ftie_F{a}(Starth:Endh,la));
                    stairs(Ftie_F{b}(Starth:Endh,lb));
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
    area(sum(Pthermal_F{a}(Starth:Endh,:),2)+Pwind_F(Starth:Endh,a)+Ppv_F(Starth:Endh,a)-sum(Ftie_F{a}(Starth:Endh,:),2),'FaceColor','k','EdgeColor','k');
    area(sum(Pthermal_F{a}(Starth:Endh,:),2)+Pwind_F(Starth:Endh,a)+Ppv_F(Starth:Endh,a),'FaceColor','r','EdgeColor','r');
    area(sum(Pthermal_F{a}(Starth:Endh,:),2)+Pwind_F(Starth:Endh,a),'FaceColor','y','EdgeColor','y');
    area(sum(Pthermal_F{a}(Starth:Endh,:),2),'FaceColor','b','EdgeColor','b');
    plot(Ppv_F(Starth:Endh,a));
    plot(Pwind_F(Starth:Endh,a));
    plot(in_full.area(a).Demand(Starth:Endh));
    plot(Ftie_F{a}(Starth:Endh,:));
    legend('Tieline','PV','Wind','Thermal','PV','Wind','Demand','Tieline');
    title(['energy distribution in area ' num2str(a)]);
    hold off;
end