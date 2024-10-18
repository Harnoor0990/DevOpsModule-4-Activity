// Input Field Nodes
const nameInputNode = document.getElementById("nameInput")
const emailInputNode = document.getElementById("emailInput")
const dropdownInputNode = document.getElementById("transportType")
const transportSurveyNode = document.getElementById("survey-form")

// event listener for triggering submit event
transportSurveyNode.addEventListener("submit", (event) => {


    const clearErrors = () => {
        const errorMessageNodes = document.querySelectorAll("error-message")

        errorMessageNodes.forEach(node => {
            node.remove();

        });
    };

    clearErrors();

    const validatedObject = validateForm();

    if (!validatedObject["isValid"]) {
        const errorMessages = validatedObject["errorMessages"];

    event.preventDefault();

        errorMessages.forEach(message => {
            showErrors(transportSurveyNode, message.fieldError);
        });
    }
});

const validateForm = () => {
    let isValid = true;
    let errorMessages = [];

    const nameIsNotEmpty = () => {
        
        let nameEntered = nameInputNode.value;

        if (nameEntered.length <= 0) {

            isValid = false;
            errorMessages.push({nameEntered, fieldError: "Name cannot be empty. "})
        }};

    const isSelected = () => {
        
        let transportationSelection = dropdownInputNode.value;

        if (transportationSelection === "") {
            isValid = false;
            errorMessages.push({transportationSelection, fieldError: "Transport type must be selected. "})
        }
    };

    const isValidEmail = () => {

        let emailInput = emailInputNode.value;

        if (emailInput === "") {

            isValid = false;
            errorMessages.push({emailInput, fieldError: "Email cannot be blank. "})
        }


        const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        if (!emailPattern.test(emailInput)) {
            isValid = false;
            errorMessages.push({emailInput, fieldError: "Please enter a valid email address. "});
        }
    };


    nameIsNotEmpty();
    isSelected();
    isValidEmail();

    return {
        isValid: isValid,
        errorMessages: errorMessages
    };

};

const showErrors = (displayErrorNode, fieldError) => {

    const errorTextNode = document.createElement("span");

        errorTextNode.setAttribute("role", "alert");
        errorTextNode.textContent = fieldError;

        errorTextNode.className = "error-message";

        displayErrorNode.appendChild(errorTextNode);
}; 