%%power distribution in PV, wind power and therma unit generation
Endh=24*56;
for a=1:A
    figure;
    hold on;
%     area(Demand(1:Endh,a),'FaceColor','g','EdgeColor','g');
    area(sum(Pthermal_F{a}(1:Endh,:),2)+Pwind_F(1:Endh,a)+Ppv_F(1:Endh,a)+sum(Ftie_F{a}(1:Endh,:),2),'FaceColor','k','EdgeColor','k');
    area(sum(Pthermal_F{a}(1:Endh,:),2)+Pwind_F(1:Endh,a)+Ppv_F(1:Endh,a),'FaceColor','r','EdgeColor','r');
    area(sum(Pthermal_F{a}(1:Endh,:),2)+Pwind_F(1:Endh,a),'FaceColor','y','EdgeColor','y');
    area(sum(Pthermal_F{a}(1:Endh,:),2),'FaceColor','b','EdgeColor','b');
    plot(Ppv_F(1:Endh,a));
    plot(Pwind_F(1:Endh,a));
    legend('Demand','PV','Wind','Thermal','PV','Wind')
    hold off;
end
