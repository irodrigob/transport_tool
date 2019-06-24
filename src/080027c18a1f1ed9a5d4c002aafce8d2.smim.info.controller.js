sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/ui/core/routing/History"
], function (Controller, JSONModel, History) {
    "use strict";
    return Controller.extend("com.irb.trans.controller.info", {
        onInit: function () {

            // Creo un modelo local para poner el icono que se mostrara en la vista
            var oViewModel = new JSONModel({
                infoIcon: ""
            });
            this.getView().setModel(oViewModel, "view");

            switch (this.getOwnerComponent().getModel("infoDialog").getProperty("/State")) {
                case sap.ui.core.ValueState.Error:
                    this.getView().getModel("view").setProperty("/infoIcon", "sap-icon://message-error");
                    break;
                case sap.ui.core.ValueState.Warning:
                    this.getView().getModel("view").setProperty("/infoIcon", "sap-icon://message-warning");
                    break;
                case sap.ui.core.ValueState.Success:
                    this.getView().getModel("view").setProperty("/infoIcon", "sap-icon://message-success");
                    break;
            }
        },
        onNavBack:function(oEvent){
            var oHistory = History.getInstance();
            var sPreviousHash = oHistory.getPreviousHash();

            if (sPreviousHash !== undefined) {
                window.history.go(-1);
            } else {
                var oRouter = sap.ui.core.UIComponent.getRouterFor(this);
                oRouter.navTo("home", true);
            }
        }

    });
});
