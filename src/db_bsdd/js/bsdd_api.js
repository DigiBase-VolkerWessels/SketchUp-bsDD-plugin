var base_url = "https://bs-dd-api-prototype.azurewebsites.net/";

function apiCall(endpoint, callback, params) {
  var url = base_url + endpoint + "?" + $.param(params, true);
  console.log(url);
  var response = null;
  $.getJSON(url, function (result) {
    callback(result);
  });
  return response;
}

// Set options for domain filter
function setDomainList() {
  apiCall('api/Domain', function (result) {
    $.each(result, function (i, item) {

      // When IFC domain guid is found start collecting IFC list
      if (item.name == 'IFC') {
        setIfcList(item.guid);
      }
      $('#inputDomain').append($('<option>', {
        value: item.guid,
        text: item.name
      }));
    });
  });
}

// Set options for language filter
function setLanguageList() {
  apiCall('api/Language', function (result) {
    $.each(result, function (i, item) {
      $('#inputLanguage').append($('<option>', {
        text: item.isoCode
      }));
    });
  });
}

// get selected ifc type from sketchup
function setIfcList(ifcDomainGuid) {
  apiCall('api/SearchListOpen', function (response) {
    ifcDomain = response.domains[0];
    classifications = ifcDomain.classifications
    $.each(classifications, function (i, entity) {
      $('#inputIfc').append($('<option>', {
        value: entity.name,
        text: entity.name
      }));
    });
    if (typeof sketchup != 'undefined') {
      sketchup.update();
    }
  }, {
    'DomainGuid': ifcDomainGuid
  });
}

function fillSelectOptions() {
  setDomainList();
  setLanguageList();
}
