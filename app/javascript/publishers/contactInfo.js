import {
  pollUntilSuccess,
  submitForm
} from '../utils/request';
import flash from '../utils/flash';
import spinner from '../utils/spinner';

document.addEventListener('DOMContentLoaded', function() {
  var updateContactInfo = document.getElementById('update_contact_info');

  if (!updateContactInfo) {
    return;
  }

  updateContactInfo.addEventListener('submit', function(event) {
    event.preventDefault();
    spinner.show();
    submitForm('update_contact_info', 'PATCH')
      .then(function() {
        return pollUntilSuccess('/publishers/domain_status', 2000, 1000, 10);
      })
      .then(function(response) {
        return response.json();
      })
      .then(function(json) {
        spinner.hide();
        if (json.error) {
          flash.clear();
          flash.append('warning', 'There were errors saving your request:');
          flash.append('warning', json.error);
        } else {
          window.location.href = json.next_step;
        }
      })
      .catch(function(e) {
        spinner.hide();
        flash.clear();
        flash.append('warning', 'An unexpected error occurred saving your changes.');
      });
  }, false);
}, false);