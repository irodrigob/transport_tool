sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/m/MessageToast"
], function (Controller, JSONModel, MessageToast) {
    "use strict";
    return Controller.extend("com.irb.trans.controller.home", {
        onInit: function () {

        },

        pressTile: function (evt) {
            if (evt.getSource().sId.indexOf("MyOrders")){

                // Leo las RFC del sistema
                dataModel.getSystem(this);

                // Leo las ordenes del usuario de conexion
                dataModel.getUserOrders(this);

                // Si no hay error en la lectura de ordenes navego hacia la vista de ordenes.
                if (this.getOwnerComponent().getModel().getProperty("/userOrdersLoad")){
                    this.getOwnerComponent().getRouter().navTo("myOrders");
                }

            }


        }

    });
});
