const quizForm = document.querySelector("#quiz-form");
const feedback = document.querySelector("#quiz-feedback");

quizForm.addEventListener("submit", (event) => {
  event.preventDefault();

  const selectedAnswer = new FormData(quizForm).get("answer");
  feedback.classList.remove("success", "error");

  if (!selectedAnswer) {
    feedback.textContent = "اختر إجابة أولًا.";
    feedback.classList.add("error");
    return;
  }

  if (selectedAnswer === "13") {
    feedback.textContent = "إجابة صحيحة: √(5² + 12²) = √169 = 13.";
    feedback.classList.add("success");
    return;
  }

  feedback.textContent = "ليست صحيحة. جرّب حساب √(25 + 144).";
  feedback.classList.add("error");
});
