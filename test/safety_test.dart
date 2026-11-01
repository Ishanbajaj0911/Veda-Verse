import 'package:flutter_test/flutter_test.dart';
import 'package:veda_verse/ai/safety.dart';

void main() {
  SafetyLevel level(String t, {List<String> earlier = const [], List<String> meds = const []}) =>
      Safety.checkMessage(t, earlier: earlier, myMedicines: meds).level;

  group('self-harm goes to Tele-MANAS 14416 + 108', () {
    for (final t in [
      'I want to kill myself',
      'I want to end my life',
      'i dont want to live anymore',
      'thinking about suicide',
      'I feel suicidal',
      'I have been cutting... I want to hurt myself',
      'sometimes I wish I was dead',
      'mai marna chahta hu',
      'jeena nahi chahti',
      'मैं आत्महत्या करना चाहता हूँ',
      'मैं मरना चाहती हूँ',
      'मुझे जीना नहीं चाहता',
    ]) {
      test(t, () => expect(level(t), SafetyLevel.selfHarm));
    }
  });

  group('medical emergencies go to 108', () {
    for (final t in [
      'I have chest pain',
      'my chest feels tight and heavy',
      'I can’t breathe properly', // curly apostrophe from phone keyboards
      'cannot breathe',
      'shortness of breath since morning',
      'I passed out this morning',
      'I feel faint and dizzy',
      'my left arm is numb and my face is drooping',
      'heavy bleeding during my period',
      'I am pregnant and bleeding',
      'I took an overdose',
      'I took too many pills',
      'my child swallowed bleach',
      'he is having a seizure',
      'my throat is swelling after eating peanuts',
      'seene mein dard ho raha hai',
      'saans nahi aa rahi',
      'papa behosh ho gaye',
      'मेरे सीने में दर्द है',
      'सांस नहीं आ रही',
      'वह बेहोश हो गई',
    ]) {
      test(t, () => expect(level(t), SafetyLevel.emergency));
    }
  });

  group('taking a medicine or substance goes to a Vaidya', () {
    for (final t in [
      'Can I take ashwagandha with my BP tablet?',
      'Can I take haldi with my metformin?',
      'how much turmeric should I take daily',
      'is it safe to stop my thyroid medication',
      'what supplement helps PCOS',
      'can I use guggul for weight loss',
      'Should I take vitamin D capsules?',
      'what kadha should I drink for cold',
      'which herb is best for sleep',
      'can I drink alcohol on weekends',
      'kaunsi dawai lu acidity ke liye',
      'मुझे कौन सी जड़ी बूटी लेनी चाहिए',
      'क्या मैं यह दवा ले सकता हूँ',
      'is paracetamol ok for my headache',
    ]) {
      test(t, () => expect(level(t), SafetyLevel.vaidya));
    }

    test('names from the user\'s own medicine list are caught', () {
      expect(level('can I have triphala tea with amlodipine?'), SafetyLevel.vaidya);
      expect(level('is Thyrocare-X fine with walking?', meds: ['Thyrocare-X 50 mcg']), SafetyLevel.vaidya);
    });

    test('a follow-up right after a medicine question stays with the Vaidya', () {
      final earlier = ['I take metformin every morning'];
      expect(level('can I have haldi with it?', earlier: earlier), SafetyLevel.vaidya);
      expect(level('ok, how much should I take?', earlier: ['is ashwagandha good for stress?']), SafetyLevel.vaidya);
      expect(level('इसे कितना लेना चाहिए?', earlier: ['क्या अश्वगंधा अच्छा है?']), SafetyLevel.vaidya);
      // An unrelated earlier chat does not block the follow-up.
      expect(level('how much should I walk?', earlier: ['what is my dosha?']), SafetyLevel.ok);
    });
  });

  group('everyday wellness questions go through', () {
    for (final t in [
      'which pillow is best for back pain',
      'is herbal tea good in winter',
      'I feel faint-hearted about exercise',
      'tips for a deep breath practice',
      'my doctor said my bp is normal, what yoga should I do',
      'how do I reduce screen time on my tablet',
      'what is a dosha',
      'foods rich in vitamin C for my skin',
      'is turmeric milk good at night',
      'how to sleep better',
      'Raat ko neend kyun nahi aati?',
      'मुझे नींद नहीं आती, क्या करूं?',
      'saans ki exercise batao',
      'I think I have food poisoning symptoms, what should I eat after',
      'best breathing exercise for stress',
    ]) {
      test(t, () => expect(level(t), SafetyLevel.ok));
    }
  });

  group('Gemini answers are checked too', () {
    test('an amount of a remedy becomes a Vaidya card', () {
      expect(Safety.checkAnswer('Take 500 mg of ashwagandha powder at night.').level, SafetyLevel.vaidya);
      expect(Safety.checkAnswer('You can take 2 tablets of triphala before bed.').level, SafetyLevel.vaidya);
    });

    test('naming a disease the user has becomes a Vaidya card', () {
      expect(Safety.checkAnswer('From what you describe, you have PCOS.').level, SafetyLevel.vaidya);
    });

    test('telling the user to change medicines becomes a Vaidya card', () {
      expect(Safety.checkAnswer('You could stop your medicine once you feel better.').level, SafetyLevel.vaidya);
    });

    test('ordinary food and routine advice passes', () {
      expect(Safety.checkAnswer('Add 1 tsp ghee to warm khichdi and sleep by 10:30 pm.').level, SafetyLevel.ok);
      expect(Safety.checkAnswer('Try 10 minutes of Anulom Vilom before bed.').level, SafetyLevel.ok);
    });

    test('repeating a condition the user entered is not a diagnosis', () {
      const greeting = 'Hello Ishan! I see you have diabetes, so let us keep meals regular.';
      expect(Safety.checkAnswer(greeting).level, SafetyLevel.vaidya, reason: 'unknown to us: still held');
      expect(Safety.checkAnswer(greeting, myConditions: {'Diabetes'}).level, SafetyLevel.ok);
      expect(Safety.checkAnswer('Since you have hypertension, keep salt low.', myConditions: {'High BP'}).level, SafetyLevel.ok);
      expect(Safety.checkAnswer('You have diabetes and you have PCOS.', myConditions: {'Diabetes'}).level, SafetyLevel.vaidya,
          reason: 'PCOS was never reported');
      expect(Safety.checkAnswer('Take 500 mg of ashwagandha.', myConditions: {'Diabetes'}).level, SafetyLevel.vaidya);
    });
  });
}
