sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel",
    "sap/m/MessageToast"
], function (Controller, JSONModel, MessageToast) {
    "use strict";
    return Controller.extend("com.irb.trans.controller.main", {
        onInit: function () {

            // Leo los datos iniciales para alimentar al modelo
            this.readInitialData();


        },

        readInitialData: function () {

            dataModel.getUserInfo(this); // Información del usuario de conexion
        }

    });
});